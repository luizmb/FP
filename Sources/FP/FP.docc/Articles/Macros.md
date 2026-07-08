# Macros

Swift macros are compile-time code generators: the compiler parses your source into a syntax tree, hands the annotated declaration to the macro's implementation (a separate `SwiftSyntax`-based plugin), and splices the returned declarations back in before type-checking. Nothing happens at runtime — `swift build` fails if a macro can't produce valid code, and `⌘-click` / "Expand Macro" in Xcode shows you exactly what was generated.

`FPMacros` ships six macros, each restricted to one **attachment kind** that determines where the generated code can go:

- **`@attached(member)`** — adds new declarations *inside* the annotated type's body (as if you'd typed them yourself between the braces). Used by `@Lenses` and `@Iso`.
- **`@attached(peer)`** — adds a new declaration *alongside* the annotated one, at the same scope, rather than inside it. Used by `@Mock` and `@Witness` (both attach to a `protocol`, and a protocol can't have members injected into a conforming type it doesn't own — the mock/witness has to be a sibling struct).
- **`@attached(extension)`** — adds a new `extension` of the annotated type, optionally declaring a protocol conformance. Used by `@Prisms` (conformance to `Prismatic`), `@DeriveMonoid` (conformance to `Monoid`), and `@Witness` (the `.witness` conversion property).

Some macros combine two attachments — `@Prisms` is both `@attached(member)` (the `Prisms` struct, `Cases` enum) and `@attached(extension)` (the `Prismatic` conformance); `@Witness` is both `@attached(peer)` (the sibling `XWitness` struct) and `@attached(extension)` (the `.witness` computed property).

All six only ever *add* declarations — they never rewrite or delete your code, and misuse (wrong attachment target, unsupported access level, an unsound generic) is caught as a compile-time diagnostic, not a runtime crash.

```swift
import FPMacros
```

---

## `@Lenses` — struct lenses + memberwise init + `with(...)`

`@attached(member, names: arbitrary)`

Applied to a struct, `@Lenses` generates:
- a memberwise `init(...)` (unless the struct already declares a conflicting one),
- a nested `Lenses: Sendable` struct holding one `Lens<Host, Property>` per stored property, plus a `static let lens` (or `static var lens` for generic hosts) accessor,
- a `with(...)` copy-with-overrides method.

**Before:**

```swift
@Lenses(init: .public)
public struct Config {
    public let host: String
    public let version = 3       // constant — no lens, excluded from init
    public var port: Int
    public var timeout = 30
}
```

**After (expanded, simplified for readability):**

```swift
public struct Config {
    public let host: String
    public let version = 3
    public var port: Int
    public var timeout = 30

    public init(host: String, port: Int, timeout: Int = 30) {
        self.host = host; self.port = port; self.timeout = timeout
    }

    public struct Lenses: Sendable {
        public let host: CoreFP.Lens<Config, String> =
            CoreFP.lens(\Config.host) { s, a in s.with(host: a) }
        public let port: CoreFP.Lens<Config, Int> = CoreFP.lens(\Config.port)
        public let timeout: CoreFP.Lens<Config, Int> = CoreFP.lens(\Config.timeout)
    }
    public static let lens = Lenses()

    public func with(host: String? = nil, port: Int? = nil, timeout: Int? = nil) -> Config {
        Config(host: host ?? self.host, port: port ?? self.port, timeout: timeout ?? self.timeout)
    }
}
```

Note the asymmetry: `port` and `timeout` (`var`) get a zero-cost `WritableKeyPath`-backed lens; `host` (`let`) gets a *reconstruction* lens that calls back into `with(...)` — which is why `with(...)` is generated as the single O(N) source of truth for reconstruction, rather than every `let` lens inlining a full field list (which would be O(N²) across N properties).

Properties whose type is `T?` get a double-Optional parameter in `with(...)` (`T?? = .some(nil)`) so `with()` (keep), `with(x: nil)` (clear), and `with(x: v)` (set) all read naturally — see `LensesMacro.makeWithFunc` for the exact encoding.

**Slicing:** `@Lenses(.all)` (default), `@Lenses(.initOnly)` (init only), `@Lenses(.lensesOnly)` (lens + with, no init — use when you already have a custom init).

**When to reach for it:** any struct you'll be updating functionally — Redux/SwiftRex `State` structs are the primary use case, since `@Lenses` composes with `>>>` across nested reducers and its `with(...)` avoids hand-writing a copy-with-overrides method per type.

---

## `@Prisms` — enum prisms + case predicates

`@attached(member, names: arbitrary)` + `@attached(extension, conformances: Prismatic)`

Applied to an enum, `@Prisms` generates:
- a nested `Prisms: Sendable` struct holding one `Prism<Host, Payload>` per case, plus `static let prism` (or `static var prism` for generic hosts),
- `Prismatic` conformance, which unlocks `Prism(\.caseName)` — composable case key paths,
- a nested `Cases: CoreFP.CaseMatchable` enum mirroring the case *names* (no payloads), plus `value.is(.caseName)`.

**Before:**

```swift
@Prisms
public enum Shape {
    case circle(Double)
    case rectangle(Double, Double)
    case empty
}
```

**After (expanded, per `PrismsMacro`, simplified for readability):**

```swift
public enum Shape {
    case circle(Double)
    case rectangle(Double, Double)
    case empty

    public struct Prisms: Sendable {
        public let circle: CoreFP.Prism<Shape, Double> = CoreFP.prism(
            preview: { (_ s: Shape) in guard case .circle(let a) = s else { return nil }; return a },
            review: Shape.circle
        )
        public let rectangle: CoreFP.Prism<Shape, (Double, Double)> = CoreFP.prism(
            preview: { (_ s: Shape) in guard case .rectangle(let v0, let v1) = s else { return nil }; return (v0, v1) },
            review: { (t: (Double, Double)) in Shape.rectangle(t.0, t.1) }
        )
        public let empty: CoreFP.Prism<Shape, Void> = CoreFP.prism(
            preview: { (_ s: Shape) in guard case .empty = s else { return nil }; return () },
            review: { (_: Void) in Shape.empty }
        )
    }
    public static let prism = Prisms()

    public enum Cases: CoreFP.CaseMatchable {
        public typealias Subject = Shape
        case circle, rectangle, empty
        public func matches(_ value: Shape) -> Bool {
            switch (self, value) {
            case (.circle, .circle): return true
            case (.rectangle, .rectangle): return true
            case (.empty, .empty): return true
            default: return false
            }
        }
    }
    public func `is`(_ c: Cases) -> Bool { c.matches(self) }
}
extension Shape: Prismatic {}
```

```swift
let s = Shape.circle(3.14)
Shape.prism.circle.preview(s)          // Optional(3.14)
Shape.prism.circle.set(s, 5.0)         // .circle(5.0)
Prism(\.circle).preview(s)             // Optional(3.14) — via the case key path
s.is(.circle)                          // true
Shape.Cases.allCases                   // [.circle, .rectangle, .empty]
```

**Slicing:** `@Prisms(.all)` (default), `@Prisms(.prisms)` (prisms + `Prismatic` only), `@Prisms(.cases)` (`Cases` + `is(_:)` only).

**When to reach for it:** any enum you inspect or transform by case — Redux/SwiftRex `Action` enums are the primary use case, mirroring `@Lenses` on the sibling `State`.

---

## `@Iso` — total isomorphism to a field tuple (or another type)

`@attached(member, names: named(iso))`

Applied to a struct, `@Iso` generates `static var iso: Iso<Self, Representation>`. With no argument, `Representation` is the single field's type (one-field struct) or a tuple of every field's type (multi-field struct) — always sound, because it round-trips through the struct's own memberwise initializer. With `@Iso(Other.self)`, `Representation` is `Other`, mapped field-by-field through *both* types' memberwise inits — convenient, but unverified: the macro can only see `Other`'s name, not its fields, so a shape mismatch surfaces as an opaque compiler error in the generated code.

**Before:**

```swift
@Iso struct Point { var x: Int; var y: Int }

@Iso struct Celsius { var value: Double }
```

**After (expanded, per `IsoMacro` and `Tests/FPMacrosTests/ProductMacroTests.swift`):**

```swift
struct Point {
    var x: Int; var y: Int
    static var iso: CoreFP.Iso<Point, (Int, Int)> {
        CoreFP.iso(get: { ($0.x, $0.y) }, reverseGet: { Point(x: $0.0, y: $0.1) })
    }
}

struct Celsius {
    var value: Double
    static var iso: CoreFP.Iso<Celsius, Double> {
        CoreFP.iso(get: { $0.value }, reverseGet: { Celsius(value: $0) })
    }
}
```

```swift
let tuple = Point.iso.get(Point(x: 1, y: 2))     // (1, 2)
Point.iso.reverseGet((3, 4))                     // Point(x: 3, y: 4)
Celsius.iso.get(Celsius(value: 36.6))            // 36.6
```

**When to reach for it:** bridging a domain struct to/from a DTO or tuple representation, or getting a reversible `Iso` for free instead of hand-writing `get`/`reverseGet`. For the library's own generic `Newtype`, prefer its built-in `Newtype.iso` instead of `@Iso`.

---

## `@DeriveMonoid` — product `Monoid` for a struct

`@attached(extension, conformances: Monoid, names: named(combine), named(identity))`

Applied to a struct whose every stored property is itself a `Monoid`, `@DeriveMonoid` synthesizes `Monoid` conformance as the field-wise **product**: `combine` combines each field with its own type's `combine`, and `identity` is each field's `identity`.

**Before:**

```swift
@DeriveMonoid
struct Stats {
    var clicks: Int.Monoids.Sum
    var ok: Bool.Monoids.And
}
```

**After (expanded, per `DeriveMonoidMacro` and `ProductMacroTests.swift`):**

```swift
struct Stats {
    var clicks: Int.Monoids.Sum
    var ok: Bool.Monoids.And
}
extension Stats: CoreFP.Monoid {
    static func combine(_ lhs: Stats, _ rhs: Stats) -> Stats {
        Stats(clicks: Int.Monoids.Sum.combine(lhs.clicks, rhs.clicks), ok: Bool.Monoids.And.combine(lhs.ok, rhs.ok))
    }
    static var identity: Stats { Stats(clicks: Int.Monoids.Sum.identity, ok: Bool.Monoids.And.identity) }
}
```

```swift
Stats.identity.clicks.rawValue   // 0
mconcat([Stats(clicks: .init(1), ok: .init(true)), Stats(clicks: .init(4), ok: .init(true))])
// Stats(clicks: 5, ok: true)
```

A bare `Int` field won't compile — plain `Int` has no canonical monoid in this library; wrap it as `Int.Monoids.Sum` or `Int.Monoids.Product` first. Generic structs work too: every generic parameter is constrained to `Monoid` in the generated `where` clause.

**When to reach for it:** aggregating structs field-by-field — counters, accumulators, combined validation/telemetry state — without hand-writing `combine`/`identity`.

---

## `@Mock` — test doubles for a protocol

`@attached(peer, names: suffixed(Mock))`, emitted behind `#if DEBUG`

Applied to a protocol, `@Mock` emits a sibling `struct <Protocol>Mock: <Protocol>` whose every requirement is backed by a stored `wrapped…` closure, with a memberwise init so a test overrides only what it needs — anything left out defaults to `fail(...)`, which crashes loudly the instant it's actually invoked (rather than silently returning a bogus value).

**Before:**

```swift
@Mock
protocol Service {
    func fetch(id: String) -> [Int]
    func save(_ value: Int) async throws
    var isReady: Bool { get }
}
```

**After (expanded, per `MockMacro` and `MockTests.swift`):**

```swift
#if DEBUG
struct ServiceMock: Service {
    var wrappedFetch: (String) -> [Int]
    var wrappedSave: (Int) async throws -> Void
    var wrappedIsReady: () -> Bool
    init(
        fetch: @escaping (String) -> [Int] = fail("Mock function not implemented for test case"),
        save: @escaping (Int) async throws -> Void = fail("Mock function not implemented for test case"),
        isReady: @escaping () -> Bool = fail("Mock function not implemented for test case")
    ) {
        self.wrappedFetch = fetch; self.wrappedSave = save; self.wrappedIsReady = isReady
    }
    func fetch(id: String) -> [Int] { wrappedFetch(id) }
    func save(_ value: Int) async throws { try await wrappedSave(value) }
    var isReady: Bool { wrappedIsReady() }
}
#endif
```

```swift
let mock = ServiceMock(isReady: { false })   // fetch/save default to fail(...), never called
mock.isReady   // false
```

Overloaded method names are disambiguated by argument label only on collision (`find(id:)` / `find(name:)` → `findWithId` / `findWithName`). `{ get set }` properties get a getter *and* a `wrapped<Name>Set` closure. Associated types become generic parameters of the mock struct. Generic methods are erased to their existential constraint when sound; unconstrained generics, `mutating`/`static`/`init`/`subscript` requirements, and protocol inheritance are all rejected with a compile-time diagnostic (a syntactic macro can't see an inherited protocol's requirements to synthesize them).

**When to reach for it:** any protocol-based dependency you need a controllable test double for, without hand-writing a mock struct per protocol.

---

## `@Witness` — a protocol's requirements as a plain `Sendable` value

`@attached(peer, names: suffixed(Witness))` + `@attached(extension, names: named(witness))`

A **witness** is the functional counterpart to a protocol existential: instead of `any P`, you hold a `PWitness` value whose fields are the protocol's methods (as `@Sendable` closures) and properties (as `@Sendable` thunks). Because it's a plain value, it can be constructed, stubbed, and composed like any other value — the building block for dependency injection without existentials or generics-everywhere.

**Before:**

```swift
@Witness
public protocol Repository<Item> {
    associatedtype Item
    associatedtype Failure: Error
    func fetch(id: String) async -> Result<Item, Failure>
    func all() -> [Item]
    var count: Int { get }
}
```

**After (expanded, per `WitnessMacro`):**

```swift
public struct RepositoryWitness<Item, Failure: Error>: Sendable {
    public var fetch: @Sendable (String) async -> Result<Item, Failure>
    public var all: @Sendable () -> [Item]
    public var count: @Sendable () -> Int
    public init(
        fetch: @escaping @Sendable (String) async -> Result<Item, Failure>,
        all: @escaping @Sendable () -> [Item],
        count: @escaping @Sendable () -> Int
    ) { self.fetch = fetch; self.all = all; self.count = count }
    public init<Base: Repository & Sendable>(_ instance: Base)
        where Base.Item == Item, Base.Failure == Failure {
        self.init(
            fetch: { await instance.fetch(id: $0) },
            all: { instance.all() },
            count: { instance.count }
        )
    }
}
public extension Repository where Self: Sendable {
    var witness: RepositoryWitness<Item, Failure> { RepositoryWitness(self) }
}
```

```swift
let repo = MemoryRepo(store: ["a": 1]).witness   // RepositoryWitness<Int, RepoError>
await repo.fetch("a")   // .success(1)
repo.count()            // 1
```

`{ get set }` requirements add a `set<Name>: @Sendable (T) -> Void` field; because the protocol's setter is `mutating`, the from-instance `init` and `.witness` are then gated to `where Self: AnyObject` (a value-type conformer can only build the witness via the memberwise init). Protocol inheritance composes by name — `PetWitness` gains an `animal: AnimalWitness` field when `Pet: Animal`, and both protocols must be `@Witness`-annotated. Same overload/generic-erasure/rejection rules as `@Mock` apply.

**When to reach for it:** dependency injection where you want a plain, `Sendable`, stub-friendly value instead of `any Protocol` — Reader-based environments are a natural fit (`Reader<RepositoryWitness<Item, Failure>, Out>`).

---

## Comparison table

| Macro | Attaches to | Attachment kind(s) | Generates | Replaces manual boilerplate for |
|---|---|---|---|---|
| `@Lenses` | `struct` | `member` | memberwise init, `Lenses` struct + `static lens`, `with(...)` | hand-written `Lens` per property + copy-with-overrides method |
| `@Prisms` | `enum` | `member` + `extension` | `Prisms` struct + `static prism`, `Prismatic` conformance, `Cases` enum, `is(_:)` | hand-written `Prism` per case + case-name predicate boilerplate |
| `@Iso` | `struct` | `member` | `static var iso: Iso<Self, Representation>` | hand-written `get`/`reverseGet` pair for a field tuple or DTO bridge |
| `@DeriveMonoid` | `struct` (all fields `Monoid`) | `extension` | `Monoid` conformance (`combine`, `identity`) | hand-written field-wise `combine`/`identity` |
| `@Mock` | `protocol` | `peer` | `#if DEBUG` sibling `<Protocol>Mock` struct | hand-written test-double struct per protocol |
| `@Witness` | `protocol` | `peer` + `extension` | sibling `<Protocol>Witness` struct + `.witness` conversion | hand-written closure-struct + `any Protocol`-to-value bridging |

## A note for Haskell developers

This article intentionally has no "for Haskell developers" translation table — macros are a Swift-specific, compile-time-metaprogramming mechanism with no direct equivalent in Haskell's runtime semantics. The closest analog is **Template Haskell** (`$(deriveLenses ''Config)`-style quasi-quotation, or `GHC.Generics`-based deriving), which also generates code from a syntax representation before compilation. But Haskell developers reaching for `@Lenses`/`@Prisms` should think less "what's the Haskell equivalent" and more "this is what `lens`'s `makeLenses` Template Haskell splice, or `DeriveGeneric` + a generic-lens library, would do for you automatically" — the goal (avoid hand-written boilerplate for structurally-derivable code) is the same; the mechanism (Swift's `SwiftSyntax`-based macro expansion vs. GHC's AST-splicing) is different.
