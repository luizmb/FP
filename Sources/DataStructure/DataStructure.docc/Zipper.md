# ``Zipper``

`Zipper<A>` is a focused, navigable non-empty sequence — the classic "list zipper": a sequence together with a distinguished cursor position (`focus`) and O(1) navigation one step in either direction. It's the canonical data structure for walking back and forth over a sequence while editing the element currently under focus.

```swift
import DataStructure

public struct Zipper<A> {
    public let left: [A]    // elements before the focus, closest-to-focus first
    public let focus: A     // the element currently under focus
    public let right: [A]   // elements after the focus, closest-to-focus first
}
```

`left` is stored in reversed order — closest-to-focus first — so that moving the cursor never requires reversing or re-indexing anything. Moving left pops the front of `left` into `focus` and pushes the old `focus` onto the front of `right`; moving right does the mirror operation. Both are O(1).

## Creating and navigating

```swift
// Direct init, cursor placed explicitly:
let z = Zipper(left: [2, 1], focus: 3, right: [4, 5])   // sequence: 1, 2, 3, 4, 5

// From a plain array, cursor starts at the first element — nil if the array is empty:
let fromArray = Zipper([1, 2, 3, 4, 5])   // focus == 1

let stepped = fromArray?.moveRight()   // focus == 2, left == [1]
stepped?.moveLeft()                    // back to focus == 1
fromArray?.moveLeft()                  // nil — already at the start

fromArray?.toArray()   // [1, 2, 3, 4, 5] — left (un-reversed) + focus + right
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

`duplicate()` builds its `left`/`right` arrays by walking `moveLeft()`/`moveRight()` repeatedly and collecting each intermediate zipper — no `Monoid` constraint required, since there's nothing to combine, only positions to visit. This is the same shape as `Reader`/`Writer`'s comonad instances, but simpler: those need an inner `Monoid` to accumulate a log or an environment, while `Zipper`'s "context" is just its own left/right neighbors.

`coflatMap` is provided as an alias for `extend`, matching the naming some Haskell comonad libraries use alongside the categorically-named `extend`.

## NonEmpty interoperability

A `Zipper` is, structurally, a `NonEmpty` with a cursor. Converting between them is lossless in one direction and position-resetting in the other:

```swift
let ne = NonEmpty(head: 1, tail: [2, 3, 4])
let z = Zipper.fromNonEmpty(ne)   // focus == 1 (the head), rest placed to the right

z.moveRight()?.toNonEmpty()   // NonEmpty(head: 1, tail: [2, 3, 4]) — full sequence,
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

`Zipper<A>` is the structure from Gérard Huet's 1997 paper "The Zipper" (the origin of the term for this whole family of focused-navigation data structures), specialized to lists — the same shape as `Data.List.Zipper` on Hackage. The `left`/`focus`/`right` triple, `left` reversed for O(1) movement, and the lawful `Comonad` instance are all direct ports of the standard presentation.

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
