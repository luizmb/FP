# ``EndoMut``

`EndoMut<A>` is the in-place counterpart to ``Endo`` — instead of wrapping `(A) -> A`, it wraps `(inout A) -> Void`, purpose-built to avoid Copy-on-Write copy costs on large Swift value types.

```swift
import CoreFP

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

## Bridging: `toEndo()` / `toEndoMut()`

``Endo`` and `EndoMut` are isomorphic as monoids. Converting `Endo → EndoMut` is free — no allocation beyond wrapping the closure. Converting `EndoMut → Endo` always makes exactly one copy, which is precisely the copy pure-function semantics require.

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

## For Haskell developers

`EndoMut` has **no Haskell equivalent** — Haskell is purely immutable, so there is no Copy-on-Write buffer to avoid re-copying in the first place; every value already behaves as if it were freshly reconstructed, and GHC's optimizer (not the type system) is responsible for eliminating redundant copies where it safely can. `EndoMut` is a pragmatic, Swift-specific addition that exists purely for value-type performance on `Array`/`Dictionary`/`String`-backed state — the same "compromise for the sake of avoiding struct/enum copies" theme that runs through this library's optics-lifting (`lift`) and `Stateful`/`EndoMut` bridging APIs more broadly. It carries the exact same `Monoid` algebra as `Endo`; it's an implementation-strategy choice, not a different abstraction.

- SeeAlso: [`Data.Monoid` (Hackage)](https://hackage.haskell.org/package/base/docs/Data-Monoid.html#t:Endo)
