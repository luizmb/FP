# ``Zipper``

`Zipper<A>` is a focused, navigable non-empty sequence — the classic "list zipper": a sequence together with a distinguished cursor position (`focus`) and O(1) navigation one step in either direction. It's the canonical data structure for walking back and forth over a sequence with a cursor, keeping every earlier position as a valid value.

```swift-sketch
import DataStructure

public struct Zipper<A> {
    public let elements: [A] // the full sequence, in order
    public let focusedIndex: Int // always a valid index of `elements`

    public var focus: A // elements[focusedIndex]
    public var left: ReversedCollection<ArraySlice<A>> // before the focus, closest-to-focus first
    public var right: ArraySlice<A> // after the focus, closest-to-focus first
}
```

A zipper is the whole sequence plus the index of the focus. Moving never writes to `elements`: `moveLeft()`/`moveRight()` return a new zipper that shares the same buffer with the index shifted by one, so they are O(1), the old zipper stays valid, and copy-on-write never triggers. `left` and `right` are lazy views into that buffer (O(1) to obtain, no copy unless you build an `Array` from them), presented closest-to-focus first like Haskell's `Data.List.Zipper`.

The trade-off versus a linked-list zipper is editing at the focus: writing to the shared buffer would copy it (O(n)). `Zipper` has no editing operations; `map` rebuilds the whole sequence, O(n), as it must.

## Creating and navigating

```swift
// Direct init, cursor placed explicitly (each side closest-to-focus first):
let z = Zipper(left: [2, 1], focus: 3, right: [4, 5])   // sequence: 1, 2, 3, 4, 5

// From a plain array, cursor at the first element, or at a given index (nil if invalid):
let fromArray = Zipper([1, 2, 3, 4, 5])                 // focus == 1
let atThird = Zipper([1, 2, 3, 4, 5], focusedAt: 2)     // focus == 3

let stepped = fromArray?.moveRight()   // focus == 2, Array(stepped.left) == [1]
stepped?.moveLeft()                    // back to focus == 1
fromArray?.moveLeft()                  // nil — already at the start

fromArray?.toArray()   // [1, 2, 3, 4, 5], the shared `elements`, O(1)
```

`isAtStart` and `isAtEnd` tell you whether `moveLeft()`/`moveRight()` would return `nil` without having to call them speculatively.

## Functor

Mapping transforms every element and leaves the cursor position untouched:

```swift
let doubled: Zipper<Int> = z.map { $0 * 2 }   // same shape, every element doubled
```

## Comonad — the type's main reason to exist

`Zipper` is a textbook `Comonad`: every position in the sequence has a well-defined "context" (everything reachable by moving left or right from there), which is exactly what `extract`/`duplicate`/`extend` need.

```swift
z.extract   // the focused value — the dual of a Monad's `pure`

// duplicate: every reachable position, each holding a whole zipper focused there
let contexts: Zipper<Zipper<Int>> = z.duplicate()
contexts.extract.toArray() == z.toArray()   // true — duplicate's own focus is `self`

// extend: compute something context-dependent at every position, in one pass
let neighborSums = z.extend { zipper in
    (zipper.moveLeft()?.focus ?? 0) + zipper.focus + (zipper.moveRight()?.focus ?? 0)
}
```

`duplicate()` builds one zipper per position, each sharing the same `elements` buffer and differing only in `focusedIndex` (O(n) total) — no `Monoid` constraint required, since there's nothing to combine, only positions to visit. `Zipper`'s "context" is just its own left/right neighbors. Only the traced comonad (`Reader` with a `Monoid` environment) needs a `Monoid` to combine positions. `Writer` as a comonad is Haskell's `Env` comonad, which needs none (this library still requires `W: Monoid` there).

`coflatMap` is provided as an alias for `extend`, matching the naming some Haskell comonad libraries use alongside the categorically-named `extend`.

## NonEmpty interoperability

A `Zipper` is, structurally, a `NonEmpty` with a cursor. Converting between them is lossless in one direction and position-resetting in the other:

```swift
let ne = NonEmpty(head: 1, tail: [2, 3, 4])
let fromNonEmpty = Zipper(ne)   // focus == 1 (the head), rest placed to the right

fromNonEmpty.moveRight()?.toNonEmpty()   // NonEmpty(head: 1, tail: [2, 3, 4]) — full sequence,
                              // regardless of where the focus currently sits
```

`toNonEmpty()` always reconstructs from the *full* sequence (`toArray()`), not from wherever the cursor happens to be — the cursor position is `Zipper`-only information that `NonEmpty` has no way to represent.

## Operators

| Operator | Behavior |
|---|---|
| `<£>` / `<&>` | Functor map |
| `£>` / `<£` | replace every element with a constant |
| `->>` / `<<-` | comonad extend — container left / function left |

There is no `<*>`/`>>-` for `Zipper` — it has no `Applicative` or `Monad` instance. A zipper's whole point is the cursor position, and neither typeclass has an obvious, lawful way to combine or sequence two different cursor positions; `Comonad` is the natural fit, `Monad` is not.

## For Haskell developers

`Zipper<A>` is the structure from Gérard Huet's 1997 paper "The Zipper" (the origin of the term for this whole family of focused-navigation data structures), specialized to lists — the same shape as `Data.List.Zipper` on Hackage. The `left`/`focus`/`right` view (each side closest-to-focus first) and the lawful `Comonad` instance are direct ports of the standard presentation. The storage differs: Haskell keeps each side as a cons list so that a move shares all but one node; here the sequence is one shared array plus an index, which gives the same persistent, O(1), non-mutating moves without per-move allocation.

| This library | Haskell parallel |
|---|---|
| `Zipper<A>` | `Data.List.Zipper`'s zipper type |
| `.extract` / `.extend` / `.duplicate` | `Control.Comonad`'s `extract` / `=>>` (or `extend`) / `duplicate` |
| `.moveLeft()` / `.moveRight()` | `Data.List.Zipper`'s `left` / `right` |
| `.coflatMap` | some comonad libraries' alternate name for `extend` |

**References:**
- Gérard Huet, ["The Zipper"](https://www.st.cs.uni-saarland.de/edu/seminare/2005/advanced-fp/docs/huet-zipper.pdf) (1997) — the paper that introduced this data structure and its navigation-by-derivative technique
- [`Control.Comonad`](https://hackage.haskell.org/package/comonad) — the `comonad` package, source of the `extract`/`extend`/`duplicate` vocabulary this type's Comonad instance follows

- SeeAlso: `NonEmpty`
