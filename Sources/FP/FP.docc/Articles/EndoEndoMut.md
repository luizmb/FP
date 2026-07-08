# Endo & EndoMut

An **endomorphism** is a function from a type to itself — `(A) -> A`. `Endo<A>` wraps one, and its defining feature is a `Monoid` instance under composition: any sequence of same-type transformations collapses into a single value via `mconcat`, with the do-nothing function as the identity element. `EndoMut<A>` is the in-place counterpart, wrapping `(inout A) -> Void` instead, purpose-built to avoid Copy-on-Write copy costs on large Swift value types.

```swift
import CoreFP
```

---

## `Endo<A>` — composable pure transformations

```swift
public struct Endo<A>: FunctionWrapper {
    public let runEndo: @Sendable (A) -> A
    public init(_ fn: @escaping @Sendable (A) -> A) { runEndo = fn }
    public func callAsFunction(_ value: A) -> A { runEndo(value) }
}
```

`Endo.combine(f, g)` applies `f` first, then `g` — left-to-right, the same order as `>>>`. `Endo.identity` is `{ $0 }`.

```swift
let trim    = Endo<String> { $0.trimmingCharacters(in: .whitespaces) }
let lower   = Endo<String> { $0.lowercased() }
let exclaim = Endo<String> { $0 + "!" }

// Fuse N transforms into 1 with the Monoid:
let normalize: Endo<String> = mconcat([trim, lower, exclaim])
normalize.runEndo("  HELLO  ")   // "hello!"
normalize("  HELLO  ")           // "hello!" — callAsFunction works too

// Or with <> (requires CoreFPOperators):
let normalize2 = trim <> lower <> exclaim
```

`mconcat([])` returns `Endo.identity` — a genuinely useful base case, since "no transforms" should mean "no-op," not a crash or a special case at the call site.

`Endo<A>` vs `Iso<A, A>` — both are endomorphisms and both form a `Monoid` under composition, but only `Iso` carries an inverse:

| | `Endo<A>` | `Iso<A, A>` |
|---|---|---|
| Stores | `(A) -> A` | `(A) -> A` + inverse `(A) -> A` |
| Reversible | no | yes — `.reverse` gives the undo |
| Use when | trimming, clamping, normalizing | rotating, scaling, unit conversion |

You can pull an `Endo` out of an `Iso<A, A>` (via `.get`), but not the reverse — invertibility has to be established up front, on both sides.

---

## `EndoMut<A>` — the same algebra, applied in place

```swift
public struct EndoMut<A>: Sendable {
    public let runEndoMut: @Sendable (inout A) -> Void
    public init(_ fn: @escaping @Sendable (inout A) -> Void) { runEndoMut = fn }
    public func callAsFunction(_ value: inout A) { runEndoMut(&value) }
}
```

### Why `Endo<A>` gets expensive on large Swift values

`Array`, `Dictionary`, `Set`, and `String` store their contents in a heap buffer tracked by a reference count. Mutation happens in place only when that count is exactly **1**; the instant it reaches 2, Swift copies the whole buffer before mutating. Calling a pure `(A) -> A` function keeps the caller's reference alive for the duration of the call — the argument is a second reference — so refcount = 2, and any mutation inside triggers an O(n) copy of the entire buffer, even to change a single element.

### Why `EndoMut` avoids that copy

`EndoMut` takes the value `inout` instead. Swift's Law of Exclusivity (SE-0176) statically guarantees no other code holds an alias to the value for the duration of the call, so the buffer's refcount is exactly 1 and Copy-on-Write mutates it in place — zero copying, regardless of size. The guarantee is enforced by the compiler, not by convention: you cannot hold a second live reference while an `inout` borrow is active, so `EndoMut` stays referentially transparent at the call site even though its body performs a literal mutation.

`EndoMut` is the **same algebra** as `Endo` — a `Monoid` under sequential application. `EndoMut.combine(f, g)` runs `f`, then `g` against the same in-place value (so `g` sees every mutation `f` made); `EndoMut.identity` is `{ _ in }`.

```swift
var items = Array(0..<10_000)

let clamp = EndoMut<[Int]> { xs in for i in xs.indices { xs[i] = min(xs[i], 100) } }
let sort  = EndoMut<[Int]> { $0.sort() }

let normalise: EndoMut<[Int]> = mconcat([clamp, sort])
normalise.runEndoMut(&items)   // clamps first, then sorts — no copies
normalise(&items)              // callAsFunction also works

// <> and mconcat follow from Semigroup/Monoid, same as Endo:
(clamp <> sort)(&items)        // same as mconcat([clamp, sort])
```

---

## Bridging: `toEndo()` / `toEndoMut()`

`Endo` and `EndoMut` are isomorphic as monoids. Converting `Endo → EndoMut` is free — no allocation beyond wrapping the closure. Converting `EndoMut → Endo` always makes exactly one copy, which is precisely the copy pure-function semantics require.

```swift
public extension Endo {
    func toEndoMut() -> EndoMut<A> { EndoMut { a in a = runEndo(a) } }
}
public extension EndoMut {
    func toEndo() -> Endo<A> {
        Endo { a in
            var copy = a
            runEndoMut(&copy)
            return copy
        }
    }
}
```

```swift
let mutating = EndoMut<String> { $0 = $0.uppercased() }
let pure = mutating.toEndo()          // Endo<String> — copies once

let pure2 = Endo<String> { $0.uppercased() }
let mutating2 = pure2.toEndoMut()     // free, no allocation
```

## When to use `Endo` vs `EndoMut`

| | `Endo<A>` | `EndoMut<A>` |
|---|---|---|
| Function type | `(A) -> A` | `(inout A) -> Void` |
| CoW containers | copied on mutation | mutated in place |
| Use when | small, value-semantic types, or you need a pure `(A) -> A` API | large types with Copy-on-Write internals (`Array`, `Dictionary`, `String`) |
| Bridgeable | `.toEndoMut()` (free) | `.toEndo()` (one copy) |

`Lens.lift(_:)`, `Prism.lift(_:)`, and `AffineTraversal.lift(_:)` all accept an `EndoMut` for the focus and produce an `EndoMut` for the whole, preserving the zero-copy guarantee whenever the lens is `WritableKeyPath`-backed — the idiomatic way to write reducers over large states without ever triggering a CoW copy of the outer type.

---

## For Haskell developers

`Endo<A>` maps directly onto `Data.Monoid`'s `Endo` newtype:

```haskell
newtype Endo a = Endo { appEndo :: a -> a }

instance Semigroup (Endo a) where
    Endo f <> Endo g = Endo (f . g)

instance Monoid (Endo a) where
    mempty = Endo id
```

One difference worth flagging: Haskell's `Endo` composes with `<>` as `f . g` — right-to-left, function-composition order, where the *right* operand runs first. This library's `Endo.combine(lhs, rhs)` runs `lhs` first, then `rhs` — left-to-right, matching `>>>` rather than `.`/`<<<`. If you want Haskell's right-to-left order, wrap with `Dual (Endo a)` in Haskell, or compose with `<<<` on this library's side.

`EndoMut` has **no Haskell equivalent** — Haskell is purely immutable, so there is no Copy-on-Write buffer to avoid re-copying in the first place; every value already behaves as if it were freshly reconstructed, and GHC's optimizer (not the type system) is responsible for eliminating redundant copies where it safely can. `EndoMut` is a pragmatic, Swift-specific addition that exists purely for value-type performance on `Array`/`Dictionary`/`String`-backed state — the same "compromise for the sake of avoiding struct/enum copies" theme that runs through this library's optics-lifting (`lift`) and `Stateful`/`EndoMut` bridging APIs more broadly. It carries the exact same `Monoid` algebra as `Endo`; it's an implementation-strategy choice, not a different abstraction.

- SeeAlso: [`Data.Monoid` (Hackage)](https://hackage.haskell.org/package/base/docs/Data-Monoid.html#t:Endo)
