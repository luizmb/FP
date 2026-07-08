# ``Endo``

An **endomorphism** is a function from a type to itself — `(A) -> A`. `Endo<A>` wraps one, and its defining feature is a `Monoid` instance under composition: any sequence of same-type transformations collapses into a single value via `mconcat`, with the do-nothing function as the identity element.

```swift
import CoreFP

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

## `EndoMut` — the in-place counterpart

For large Copy-on-Write values (`Array`, `Dictionary`, `Set`, `String`), a pure `(A) -> A` transform forces a full-buffer copy on every call, because the argument keeps a second live reference alive for the duration of the call. `EndoMut<A>` wraps `(inout A) -> Void` instead, sidestepping that copy entirely via Swift's exclusivity guarantee. See ``EndoMut`` for the full treatment, the bridging (`.toEndo()`/`.toEndoMut()`), and when to reach for which.

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

- SeeAlso: [`Data.Monoid` (Hackage)](https://hackage.haskell.org/package/base/docs/Data-Monoid.html#t:Endo)
