# Semigroup and Monoid

A **Semigroup** is any type where two values combine into one value of the same type, as long as
combining is *associative* — it shouldn't matter how you group the operations, only their order.
You already know several: string concatenation, array concatenation, set union.

```swift
import CoreFP

String.combine("Hello, ", "World!")   // "Hello, World!"
Array.combine([1, 2], [3, 4])         // [1, 2, 3, 4]

// Associativity: these are always equivalent —
String.combine(String.combine("a", "b"), "c")   // "abc"
String.combine("a", String.combine("b", "c"))   // "abc"
```

A **Monoid** is a `Semigroup` with one extra requirement: a neutral element, `identity`, that
leaves any value unchanged when combined with it on either side.

```swift
"" <> "hello"    // "hello" — "" is the identity for String
[Int].identity   // []      — [] is the identity for Array
```

---

## The protocols

```swift
protocol Semigroup: Sendable {
    static func combine(_ lhs: Self, _ rhs: Self) -> Self
    static func sconcat(_ first: Self, _ rest: [Self]) -> Self   // customization point, has a default
}

protocol Monoid: Semigroup {
    static var identity: Self { get }
    static func mconcat(_ values: [Self]) -> Self                // customization point, has a default
}
```

`sconcat` and `mconcat` both have default implementations (a left fold via `combine`, and
`identity` for the empty case respectively) — most conformers never need to override them. A type
whose `combine` copies a growing accumulator (any concatenative type — `Array`, `String`) should
override `sconcat` with a single-pass build to avoid the O(n²) default.

---

## `<>`, `sconcat`, `mconcat`

`<>` (from `CoreFPOperators`) is the infix form of `combine`. `sconcat` folds a non-empty
sequence and works for `Semigroup`-only types (no `identity` required); `mconcat` folds a
possibly-empty array and requires `Monoid`, returning `identity` for `[]`:

```swift
"Hello, " <> "World!"                    // "Hello, World!"
sconcat("Hello", [", ", "World", "!"])   // "Hello, World!"
mconcat(["Hello", ", ", "World", "!"])   // "Hello, World!"
mconcat([String]())                      // "" — empty input returns identity
```

---

## Standard conformances

| Type | `combine` | `identity` |
|---|---|---|
| `[A]` | concatenation | `[]` |
| `String` | concatenation | `""` |
| `Set<A>` | union | `Set()` |
| `Dictionary<K, V>` | merge (right-biased) | `[:]` |
| `Optional<A: Semigroup>` | both present → combine; one `nil` → the other; both `nil` → `nil` | `nil` |
| `Endo`\<A\> | left-to-right function composition | `Endo { $0 }` |
| `EndoMut`\<A\> | sequential in-place application | `EndoMut { _ in }` |
| `Iso`\<A, A\> | left-to-right composition | `Iso.id` |

`Optional<A>` matches Haskell's `Maybe` instance exactly:

```swift
let a: String? = "hello"
let b: String? = " world"

Optional<String>.combine(a, b)          // Optional("hello world")
Optional<String>.combine(a, .none)      // Optional("hello")
Optional<String>.combine(.none, .none)  // nil
mconcat([a, .none, b])                  // Optional("hello world")
```

---

## Numbers and Booleans need named wrappers

`Int` has more than one natural monoid — you can add or multiply — and Swift forbids the same
type conforming to a protocol twice. Every ambiguous case in this library is solved the same way:
a lightweight `RawRepresentable` newtype, one per operation, namespaced under `.Monoids`.

| Wrapper | Operation | Identity | Constraint |
|---|---|---|---|
| `T.Monoids.Sum` | `+` | `0` | `Numeric` |
| `T.Monoids.Product` | `*` | `1` | `Numeric` |
| `T.Monoids.Min` | `min(_:_:)` | `T.max` | `Numeric & HasMax` |
| `T.Monoids.Max` | `max(_:_:)` | `T.min` | `Numeric & HasMin` |
| `Bool.Monoids.And` | `&&` | `true` | — |
| `Bool.Monoids.Or` | `\|\|` | `false` | — |
| `Bool.Monoids.Xor` | `!=` | `false` | — |

Every standard integer/float type gets a `Monoids` alias (`Int.Monoids`, `Double.Monoids`, …),
backed by `NumericMonoid<T>`:

```swift
Int.Monoids.Sum.combine(3, 4)                        // Sum(7)
mconcat([1, 2, 3] as [Int.Monoids.Sum]).rawValue      // 6

Int.Monoids.Product.combine(3, 4)                     // Product(12)
mconcat([2, 3, 4] as [Int.Monoids.Product]).rawValue  // 24

Int.Monoids.Min.combine(7, 3)                         // Min(3) — identity is Int.max
Int.Monoids.Max.combine(7, 3)                         // Max(7) — identity is Int.min

Bool.Monoids.And.combine(true, false)                 // And(false) — identity is true
Bool.Monoids.Or.combine(false, true)                  // Or(true)   — identity is false
Bool.Monoids.Xor.combine(true, true)                  // Xor(false) — identity is false
```

SIMD vector types (`SIMD2` … `SIMD64`) get the same four wrappers via `SIMDMonoid<T>`, applied
element-wise — integer scalars use wrapping arithmetic (`&+`, `&*`), floats use standard
arithmetic:

```swift
let a = SIMD4<Int>.Monoids.Sum(SIMD4(1, 2, 3, 4))
let b = SIMD4<Int>.Monoids.Sum(SIMD4(10, 20, 30, 40))
SIMD4<Int>.Monoids.Sum.combine(a, b).rawValue   // SIMD4(11, 22, 33, 44)
```

---

## `Min`, `Max`, `First`, `Last`, `Dual` — Semigroup only, by design

`Int.Monoids.Min`/`Max` need `HasMax`/`HasMin` to supply an identity (`T.max`/`T.min`). But
`min`/`max`-by-comparison, "keep the first," and "keep the last" are useful for **any**
`Comparable` (or even any) type — `String`, `Date`, custom structs — and there's no universal
"positive infinity" for an arbitrary `Comparable` type. So these four wrappers deliberately stop
at `Semigroup`, with no `identity`:

| Type | Operation | Identity |
|---|---|---|
| `Min<T: Comparable>` | `Swift.min(_:_:)` | none — `Semigroup` only |
| `Max<T: Comparable>` | `Swift.max(_:_:)` | none — `Semigroup` only |
| `First<T>` | keep the left-hand value | none — `Semigroup` only |
| `Last<T>` | keep the right-hand value | none — `Semigroup` only |
| `Dual<T: Semigroup>` | `T.combine` with operands swapped | `T.identity`, when `T: Monoid` |

```swift
sconcat(Min(5), [Min(1), Min(9), Min(3)]).rawValue    // 1
sconcat(Max(5), [Max(1), Max(9), Max(3)]).rawValue    // 9
sconcat(First("prod"), [First("staging"), First("dev")]).rawValue   // "prod"
sconcat(Last("prod"), [Last("staging"), Last("dev")]).rawValue      // "dev"

// Dual reverses the direction of combination — visible for non-commutative semigroups:
sconcat(Dual("a"), [Dual("b"), Dual("c")]).rawValue    // "cba" (String's own <> would give "abc")
```

`Dual<T>` conforms to `Monoid` whenever `T` does — swapping the operands of
`combine(identity, x)` still yields `x`, so `Dual`'s identity is just `T.identity` unchanged.

---

## `Ordering` — composite comparators

`Ordering` wraps `ComparisonResult` and combines by **short-circuiting lexicographic priority**:
the first operand that isn't a tie wins; a tie falls through to the next. This is exactly the
algebra behind multi-key sort comparators — chain one `Ordering` per sort key, and let `mconcat`
pick the first one that actually discriminates.

```swift
struct Person { let lastName: String; let firstName: String; let age: Int }

let byLastName  = comparing { (p: Person) in p.lastName }
let byFirstName = comparing { (p: Person) in p.firstName }
let byAge       = comparing { (p: Person) in p.age }

let compare: (Person, Person) -> Ordering = { l, r in
    mconcat([byLastName(l, r), byFirstName(l, r), byAge(l, r)])
}

people.sorted { compare($0, $1).rawValue == .orderedAscending }
```

`Ordering`'s identity is `.orderedSame` — an empty `mconcat` (or a chain where every comparator
ties) reports "equal," which is the correct behavior for `ORDER BY` with zero remaining keys.

---

## Composing several monoids with `mconcat`

Because every wrapper above is a `Monoid`, `mconcat` folds any of them uniformly, and `Ordering`
composes cleanly with `comparing` to build one comparator out of several:

```swift
struct Player { let team: String; let score: Int; let name: String }

let roster = [
    Player(team: "B", score: 10, name: "Zoe"),
    Player(team: "A", score: 10, name: "Amy"),
    Player(team: "A", score: 20, name: "Bo"),
]

// Sort by team, then by score descending, then by name — three composed comparators:
let byTeam  = comparing { (p: Player) in p.team }
let byScore = comparing { (p: Player) in Int.Monoids.Max($0.score).rawValue }
let byName  = comparing { (p: Player) in p.name }

let sorted = roster.sorted { l, r in
    mconcat([byTeam(l, r), byScore(r, l), byName(l, r)]).rawValue == .orderedAscending
}
// [Player(team: "A", score: 20, name: "Bo"), Player(team: "A", score: 10, name: "Amy"),
//  Player(team: "B", score: 10, name: "Zoe")]
```

---

## Module

```swift
import CoreFP           // Semigroup, Monoid protocols; sconcat/mconcat; all named wrappers
import CoreFPOperators  // adds <>
```

---

## For Haskell developers

`Semigroup` and `Monoid` here are a direct, non-typeclass-hierarchy port of `base`'s
`Data.Semigroup` / `Data.Monoid` — Swift's protocols play the role of Haskell's type classes, and
because Swift forbids conforming the same concrete type to a protocol twice, ambiguous instances
(`Int` under `+` vs. under `*`) become explicit newtypes instead of `newtype`-derived ones.

| This library | Haskell (`Data.Semigroup` / `Data.Monoid`) |
|---|---|
| `Semigroup` protocol, `combine` | `Semigroup` class, `(<>)` |
| `Monoid` protocol, `identity` | `Monoid` class, `mempty` |
| `sconcat` | `sconcat` (`Data.List.NonEmpty`) |
| `mconcat` | `mconcat` |
| `T.Monoids.Sum` | `Sum` |
| `T.Monoids.Product` | `Product` |
| `Bool.Monoids.And` | `All` |
| `Bool.Monoids.Or` | `Any` |
| `Min<T>` | `Min` (`Data.Semigroup`) |
| `Max<T>` | `Max` (`Data.Semigroup`) |
| `First<T>` / `Last<T>` | `First` / `Last` (`Data.Semigroup` — the non-`Maybe`-wrapping ones, not `Data.Monoid`'s) |
| `Dual<T>` | `Dual` |
| `Ordering` + `comparing` | the `Ordering` type's own `Monoid` instance (`Prelude`) + `comparing` (`Data.Ord`) |

- [`Data.Monoid` on Hackage](https://hackage.haskell.org/package/base/docs/Data-Monoid.html) —
  `Sum`, `Product`, `All`, `Any`, `Dual`, and the rest of the standard newtype wrappers.
- [`Data.Semigroup` on Hackage](https://hackage.haskell.org/package/base/docs/Data-Semigroup.html)
  — `Min`, `Max`, `First`, `Last`, and the `Semigroup` class itself (split from `Monoid` since
  base 4.9, mirroring the split modeled here).
