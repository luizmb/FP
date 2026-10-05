# Optics

An **optic** is an immutable value that packages a getter and a setter (or their generalisations)
into a single composable unit. Swift has no built-in notion of "a first-class reference to a
field" — `\User.name` is a `KeyPath`, but you cannot compose two `KeyPath`s that cross an enum
case, and there is no `WritableKeyPath` for "the payload of this enum case, if it's currently
active." Optics fill that gap: `Lens`, `Prism`, `AffineTraversal`, `Iso`, and `Traversal` are
plain structs holding `@Sendable` closures, so they compose with `>>>` / `<<<` exactly like
functions, and they carry no dependency on Swift's key-path machinery beyond construction.

```swift
import CoreFP

struct Address: Sendable { var city: String }
struct User: Sendable { var name: String; var address: Address }

let cityLens: Lens<User, String> = lens(\User.address) >>> lens(\Address.city)

let user = User(name: "Alice", address: Address(city: "Berlin"))
_ = cityLens.get(user)                 // "Berlin"
_ = cityLens.set(user, "Munich")       // User(name: "Alice", address: Address(city: "Munich"))
```

---

## The optic hierarchy

Every optic focuses on some `A` inside a whole `S`, but they differ in how many `A`s might be
there and whether the whole/part relationship is reversible:

| Optic | Focus | Core operations | Use it for |
|---|---|---|---|
| `Iso` | exactly one `A`, losslessly convertible back to `S` | `get`, `reverseGet` | unit conversions, wrapper types, bijections |
| `Lens` | exactly one `A`, always present | `get`, `set`, `modifyMut` | struct fields |
| `Prism` | zero or one `A` | `preview`, `review`, `tryModifyMut` | enum cases |
| `AffineTraversal` | zero or one `A` | `preview`, `set`, `tryModifyMut` | a struct field that's itself an optional case (Lens ∘ Prism) |
| `Traversal` | zero, one, or many `A`s | `getAll`, `modifyMut` | every element of a collection field |

`Iso` is the strongest — a total, invertible conversion. `Traversal` is the weakest and most
general — every other optic widens to it. Composing any two optics in the table always yields
the *weaker* of the two (or the same kind, if they're equal in strength).

---

## `Iso` — bidirectional, lossless conversion

An `Iso<S, A>` is a pair of total functions, `get: (S) -> A` and `reverseGet: (A) -> S`, that are
mutual inverses. Unlike the other optics, there's no notion of "focusing on part of a whole" —
the entire value converts back and forth without loss.

```swift
let metersToFeet = iso(
    get: { (meters: Double) in meters * 3.28084 },
    reverseGet: { (feet: Double) in feet / 3.28084 }
)

_ = metersToFeet.get(1.0)             // 3.28084
_ = metersToFeet.reverseGet(3.28084)  // 1.0
_ = metersToFeet.reverse.get(3.28084) // 1.0, reverse swaps get/reverseGet
```

`over` applies a transform through the round trip, and every `Iso` can be viewed as a `Lens`,
`Prism`, or `AffineTraversal` via `.asLens` / `.asPrism` / `.asAffineTraversal`:

```swift
_ = metersToFeet.over { $0 + 10 }(1.0)   // convert to feet, add 10, convert back to meters

let asLens: Lens<Double, Double> = metersToFeet.asLens
```

When `S == A` (an endomorphism iso), `Iso<A, A>` forms a `Monoid` under composition, so a chain
of lossless transforms can be built with `mconcat`:

```swift
struct Point: Sendable { var x: Double; var y: Double }

let rotate: Iso<Point, Point> = iso(get: { Point(x: $0.y, y: $0.x) }, reverseGet: { Point(x: $0.y, y: $0.x) })
let scale: Iso<Point, Point> = iso(get: { Point(x: $0.x * 2, y: $0.y * 2) }, reverseGet: { Point(x: $0.x / 2, y: $0.y / 2) })
let translate: Iso<Point, Point> = iso(get: { Point(x: $0.x + 1, y: $0.y) }, reverseGet: { Point(x: $0.x - 1, y: $0.y) })

let transform: Iso<Point, Point> = mconcat([rotate, scale, translate])
let point = Point(x: 1, y: 2)
_ = transform.get(point)          // all three applied in order
_ = transform.reverse.get(point)  // all three reversed, in reverse order
```

---

## `Lens` — functional getter/setter for structs

A `Lens<S, A>` focuses on exactly one field of a struct. The preferred constructor lifts a
`WritableKeyPath`:

```swift
struct Person: Sendable { var name: String; var age: Int }

let ageLens: Lens<Person, Int> = lens(\Person.age)

let person = Person(name: "Alice", age: 30)
_ = ageLens.get(person)                      // 30
_ = ageLens.set(person, 31)                  // Person(name: "Alice", age: 31)
_ = ageLens.over { $0 + 1 }(person)          // Person(name: "Alice", age: 31)
```

For `let` properties (no `WritableKeyPath` exists), supply the setter explicitly:

```swift
struct ImmutablePerson: Sendable { let name: String; let age: Int }

let nameLens: Lens<ImmutablePerson, String> = lens(\ImmutablePerson.name) { p, n in
    ImmutablePerson(name: n, age: p.age)
}
```

`Lens<A, A>.id` is the identity lens — the neutral element for composition.

---

## `Prism` — functional getter/setter for enums

A `Prism<S, A>` focuses on one case of an enum. Where a lens's focus always exists, a prism's
focus is optional — the enum might currently be a different case.

```swift
enum Shape: Sendable { case circle(Double); case rectangle(Double, Double) }

let circlePrism: Prism<Shape, Double> = prism(
    preview: { if case .circle(let r) = $0 { return r } else { return nil } },
    review: Shape.circle
)

_ = circlePrism.preview(.circle(5.0))               // Optional(5.0)
_ = circlePrism.preview(.rectangle(3, 4))           // nil
_ = circlePrism.review(7.0)                         // Shape.circle(7.0)
_ = circlePrism.over { $0 * 2 }(.circle(5))         // Shape.circle(10.0)
_ = circlePrism.over { $0 * 2 }(.rectangle(3, 4))   // Shape.rectangle(3, 4), unchanged
```

If the enum has an optional-returning computed property, the `KeyPath` shorthand is more concise:

```swift
extension Shape {
    var circleRadius: Double? {
        guard case .circle(let r) = self else { return nil }
        return r
    }
}

let circleRadiusPrism: Prism<Shape, Double> = prism(\.circleRadius, review: Shape.circle)
```

`Prism<A, A>.id` is the identity prism — preview always succeeds, review is the identity.

---

## `AffineTraversal` — assembling Lens and Prism

An `AffineTraversal<S, A>` is what you get by composing a `Lens` with a `Prism` (in either
order): the whole `S` is always present (the Lens property), but the focused `A` may be absent
(the Prism property).

```swift
struct Canvas: Sendable { var shape: Shape }

let shapeLens: Lens<Canvas, Shape> = lens(\Canvas.shape)

let circleRadiusTraversal = shapeLens >>> circlePrism   // AffineTraversal<Canvas, Double>

let canvas = Canvas(shape: .circle(5.0))
_ = circleRadiusTraversal.preview(canvas)               // Optional(5.0)
_ = circleRadiusTraversal.set(canvas, 10.0)             // Canvas(shape: .circle(10.0))

let rectCanvas = Canvas(shape: .rectangle(3, 4))
_ = circleRadiusTraversal.preview(rectCanvas)           // nil
_ = circleRadiusTraversal.set(rectCanvas, 10.0)         // Canvas(shape: .rectangle(3, 4)), unchanged
```

Collection subscripts also produce affine traversals — `ix` focuses on "the element at this
position or key, if it exists":

```swift
struct Item: Identifiable, Sendable { var id: Int }
let someId = 42

_ = [Int].ix(2)                        // AffineTraversal<[Int], Int>
_ = [Item].ix(id: someId)              // AffineTraversal<[Item], Item>
_ = [String: Int].ix(key: "count")     // AffineTraversal<[String: Int], Int>
```

A `WritableKeyPath` to an already-optional property lifts directly, without composing a
separate Lens and Prism:

```swift
struct Profile: Sendable { var nickname: String? }

let nicknameFocus = affineTraversal(\Profile.nickname)   // AffineTraversal<Profile, String>
_ = nicknameFocus.preview(Profile(nickname: "ace"))          // Optional("ace")
_ = nicknameFocus.set(Profile(nickname: nil), "ace")         // Profile(nickname: Optional("ace"))
```

---

## `Traversal` and `IndexedTraversal` — zero, one, or many foci

`Traversal<S, A>` generalises `AffineTraversal` from "0 or 1 focus" to "0 to *n* foci." It's the
weakest optic — composing anything with a `Traversal` collapses the result to a `Traversal`. The
canonical source is a collection's `.each`:

```swift
let allScores: Traversal<[Int], Int> = [Int].each
_ = allScores.getAll([10, 20, 30])            // [10, 20, 30]
_ = allScores.over { $0 + 1 }([10, 20, 30])   // [11, 21, 31]

// Composed with an outer Lens:
struct Employee: Sendable { var city: String }
struct Company: Sendable { var employees: [Employee] }

let allCityNames: Traversal<Company, String> =
    ^\Company.employees >>> [Employee].each >>> ^\Employee.city
```

`IndexedTraversal<S, I, A>` is the indexed variant — `getAll` returns `(index, focus)` pairs, so
consumers can tell foci apart (array position, dictionary key, element id):

```swift
struct Player: Sendable { var name: String }
let roster = [Player(name: "p0"), Player(name: "p1")]

let players: IndexedTraversal<[Player], Int, Player> = [Player].eachIndexed
_ = players.getAll(roster)          // [(0, p0), (1, p1)]

// Drop the index to recover a plain Traversal:
_ = players.traversal.getAll(roster)   // [p0, p1]
```

---

## Composition — `>>>` and `<<<`

All five optic types compose left-to-right with `>>>` (or right-to-left with `<<<`, from
`CoreFPOperators`). Without `CoreFPOperators`, the equivalent named method is `.compose(_:)`:

```swift
let userCityLens: Lens<User, String> = lens(\User.address).compose(lens(\Address.city))   // no operators needed
let userCityLens2: Lens<User, String> = ^\User.address >>> ^\Address.city                 // same, with operators
```

The result type follows the strength of the weaker operand:

| LHS ＼ RHS | `Lens<A,B>` | `Prism<A,B>` | `AffineTraversal<A,B>` | `Iso<A,B>` | `Traversal<A,B>` |
|---|---|---|---|---|---|
| `Lens<S,A>` | `Lens<S,B>` | `AffineTraversal<S,B>` | `AffineTraversal<S,B>` | `Lens<S,B>` | `Traversal<S,B>` |
| `Prism<S,A>` | `AffineTraversal<S,B>` | `Prism<S,B>` | `AffineTraversal<S,B>` | `Prism<S,B>` | `Traversal<S,B>` |
| `AffineTraversal<S,A>` | `AffineTraversal<S,B>` | `AffineTraversal<S,B>` | `AffineTraversal<S,B>` | `AffineTraversal<S,B>` | `Traversal<S,B>` |
| `Iso<S,A>` | `Lens<S,B>` | `Prism<S,B>` | `AffineTraversal<S,B>` | `Iso<S,B>` | `Traversal<S,B>` |
| `Traversal<S,A>` | `Traversal<S,B>` | `Traversal<S,B>` | `Traversal<S,B>` | `Traversal<S,B>` | `Traversal<S,B>` |

`^` (prefix, from `CoreFPOperators`) lifts a `WritableKeyPath` straight into a `Lens`, so chains
read as a sequence of focus steps:

```swift
enum App: Sendable { case loggedIn(User); case guest }

let loggedInPrism: Prism<App, User> = prism(
    preview: { if case .loggedIn(let u) = $0 { return u } else { return nil } },
    review: App.loggedIn
)

let cityInLoggedInUser: AffineTraversal<App, String> = loggedInPrism >>> ^\User.address >>> ^\Address.city

_ = cityInLoggedInUser.preview(.loggedIn(User(name: "Bob", address: Address(city: "Paris"))))  // Optional("Paris")
_ = cityInLoggedInUser.preview(.guest)                                                         // nil
```

### Mixed key paths — `\.a.b.c` across structs and enums

Once a type's enum conforms to `Prismatic` (which `@Prisms` generates automatically), you can
write a single dotted key path that threads through both struct fields and enum cases, and
recover it as a concrete optic:

```swift
struct Permissions: Sendable { var canDelete: Bool }

@Prisms enum Role: Sendable { case admin(Permissions); case guest }
struct Member: Sendable { var role: Role }
struct Workspace: Sendable { var member: Member }

// \.member.role.admin : AffineKeyPath<Workspace, Permissions>
let perms: AffineTraversal<Workspace, Permissions> = AffineTraversal(\.member.role.admin)
```

`Prism(\.someCase)` performs the enum-only equivalent when every step is a case (via
`PrismFocus`); `AffineTraversal(\.a.b.c)` handles a mix of struct fields and enum cases (via
`AffineFocus`).

---

## Zero-copy mutation — `EndoMut` and `lift`

`over` always returns a new `S` — one copy per call, unavoidable given its contract. When `S`
holds a copy-on-write buffer (`Array`, `Dictionary`, `String`), even a single-element change can
trigger an O(n) heap copy if the buffer's refcount was bumped by passing `S` around by value.

Every optic exposes `lift(_:)`, which converts an `EndoMut<A>` (an in-place mutation of the
focus) into an `EndoMut<S>` (an in-place mutation of the whole), threading `inout` all the way
through instead of reconstructing `S`:

```swift
let incrementAge = EndoMut<Int> { $0 += 1 }
let personReducer: EndoMut<Person> = lens(\Person.age).lift(incrementAge)

var mutablePerson = Person(name: "Alice", age: 30)
personReducer(&mutablePerson)   // mutates mutablePerson.age in place, zero copies of Person
```

When every `Lens` in the chain is `WritableKeyPath`-backed, the whole chain is zero-copy end to
end via Swift's modify coroutine. A `Prism` in the chain always copies its enum case's associated
value once (Swift has no modify coroutine for enum payloads) but never copies the outer `S`; an
`AffineTraversal` built from `ix` on a `MutableCollection` is zero-copy, while `ix` on a
`Dictionary` copies the `Value` once. Prefer `over` in pure pipelines that need a new `S`; prefer
`lift` when threading `EndoMut` reducers through large CoW state (this is exactly the pattern
SwiftRex-style reducers use).

---

## Deriving optics with macros — `@Lenses` and `@Prisms`

Writing lenses and prisms by hand for every field and case doesn't scale. `@Lenses` and `@Prisms`
generate them at compile time from the type declaration itself.

```swift
import FPMacros

@Lenses(init: .public)
public struct Config: Sendable {
    public let host: String
    public var port: Int
    public var timeout = 30
}
```

expands to a memberwise `init`, a `Config.Lenses` struct with one `Lens<Config, _>` per stored
property, a `Config.lens` static accessor, and a `with(...)` copy-with-overrides helper:

```swift
let config = Config(host: "localhost", port: 8080)

_ = Config.lens.host.set(config, "example.com")     // Config(host: "example.com", port: 8080, timeout: 30)
_ = Config.lens.port.over({ $0 + 1 })(config)       // Config(host: "localhost", port: 8081, timeout: 30)
_ = config.with(port: 9090)                          // same effect, no lens needed

// Generated lenses compose exactly like hand-written ones:
struct Team: Sendable { var teamConfig: Config }

let teamConfigHost = lens(\Team.teamConfig) >>> Config.lens.host
```

`@Prisms` does the enum equivalent — one `Prism` per case, a `Figure.prism` accessor, a plain
per-case property delegating to it, `Prismatic` conformance (unlocking `\.case` mixed key
paths), and a `Shape.Cases` mirror enum for payload-free case queries:

```swift
@Prisms
public enum Figure: Sendable {
    case circle(Double)
    case rectangle(Double, Double)
    case empty
}

let s = Figure.circle(3.14)
_ = s.circle                                // Optional(3.14), plain per-case property
_ = Figure.prism.circle.set(s, 5.0)          // Figure.circle(5.0)
_ = s.is(.circle)                            // true, case-name query, no dummy payload needed
_ = Figure.Cases.allCases                    // [.circle, .rectangle, .empty]
```

Both macros use `@attached(member)`, so they work at any nesting depth — the common pattern in
unidirectional architectures where a reducer owns nested `State` and `Action` types:

```swift
struct Reducer {
    @Lenses(init: .internal)
    struct State: Sendable { let userName: String; var score: Int }

    @Prisms
    enum Action: Sendable { case updateName(String); case incrementScore(Int) }
}

let state = Reducer.State(userName: "Alice", score: 1)
let action = Reducer.Action.updateName("Bob")

_ = Reducer.State.lens.score.over({ $0 + 10 })(state)
_ = Reducer.Action.prism.updateName.preview(action)   // Optional("Bob")
```

`@Lenses` and `@Prisms` both reject `private` declarations at compile time (use `fileprivate`
instead — identical semantics at file scope, and it doesn't break the generated namespace's
visibility). `Either`, `Validation`, `Loading`, `Optional`, and `Result` all ship with
hand-written `@Prisms`-equivalent surface out of the box.

---

## SwiftUI `Binding` bridge

On Apple platforms, `Binding[optic:]` projects a `Binding<S>` through any optic:

```swift
import SwiftUI

struct NameEditor: View {
    @State var user = User(name: "Alice", address: Address(city: "Berlin"))
    @State var app: App = .guest

    var body: some View {
        TextField("Name", text: $user[optic: lens(\User.name)])             // Lens → Binding<A> (always valid)

        if let cityBinding = $app[optic: loggedInPrism >>> ^\User.address >>> ^\Address.city] {
            TextField("City", text: cityBinding)                             // Prism/AffineTraversal → Binding<A>?
        }
    }
}
```

`Lens` and `Iso` always produce a `Binding<A>` (the focus always exists); `Prism` and
`AffineTraversal` produce `Binding<A>?` (`nil` when the focus is currently absent). The
platform-neutral equivalent, `WritableFocus`, carries the same `[optic:]` subscripts without
any SwiftUI/UIKit/AppKit dependency, so the same optic-projection pattern works on Linux, Windows,
and Android:

```swift
final class Box<A: Sendable>: @unchecked Sendable { // example storage, access is single-threaded here
    var value: A
    init(_ value: A) { self.value = value }
}

let box = Box(User(name: "Alice", address: Address(city: "Berlin")))
let focus = WritableFocus(get: { box.value }, set: { box.value = $0 })
focus.name.wrappedValue = "Bob"              // struct-field navigation, live write
_ = focus[optic: cityLens].wrappedValue      // optic projection
```

---

## Module

```swift
import CoreFP           // Iso, Lens, Prism, AffineTraversal, Traversal, IndexedTraversal, compose
import CoreFPOperators  // >>>, <<<, ^ for optic composition and construction
import FPMacros         // @Lenses, @Prisms
```

---

## For Haskell developers

This library's optics are a concrete, HKT-free encoding of the same hierarchy popularised by
Edward Kmett's `lens` package — built from plain structs holding closures rather than
van Laarhoven-encoded rank-2 functions, since Swift has no higher-kinded types to express
`Functor f => (a -> f b) -> s -> f t` generically.

| This library | Haskell (`lens` package) |
|---|---|
| `Iso<S, A>` | `Iso s a` |
| `Lens<S, A>` | `Lens s a` |
| `Prism<S, A>` | `Prism s a` |
| `AffineTraversal<S, A>` | closest to `AffineTraversal s a` (`lens-family`/`optics`) — a traversal with at most one target |
| `Traversal<S, A>` | `Traversal s a` |
| `optic1 >>> optic2` | `optic1 . optic2` (composition direction matches: outermost first) |
| `lens.get` / `prism.preview` | `view` / `preview` (`^.` / `^?`) |
| `lens.set` / `prism.review` | `set` (`.~`) / `review` (`#`) |
| `optic.over(f)` | `over` (`%~`) |
| `@Lenses`, `@Prisms` | `makeLenses`, `makePrisms` (Template Haskell) |

- [`lens` package documentation on Hackage](https://hackage.haskell.org/package/lens) — the
  canonical Haskell optics library this hierarchy is modelled after.
- [`Control.Lens.TH`](https://hackage.haskell.org/package/lens/docs/Control-Lens-TH.html) — the
  Template Haskell module providing `makeLenses` and `makePrisms`, the direct inspiration for
  `@Lenses` and `@Prisms`.
