# ``NonEmpty``

`NonEmpty<A>` is a sequence statically guaranteed to contain at least one element. The **head** is always present; the **tail** may be empty.

This eliminates an entire class of runtime crashes: any function returning `NonEmpty<A>` cannot produce an empty collection, so callers never need to guard against emptiness.

```swift
import DataStructure

// Construction
let ne  = NonEmpty(head: 1, tail: [2, 3])
let one = NonEmpty(head: 42)                  // single element
let fn  = nonEmpty(head: 1, tail: [2, 3])     // free function — same as init
let opt = nonEmpty([1, 2, 3])                 // NonEmpty<Int>? — nil if array empty
let none = nonEmpty([Int]())                  // nil

ne.head    // 1
ne.tail    // [2, 3]
ne.last    // 3
ne.count   // 3
ne.toArray // [1, 2, 3]
```

---

## Primitives

```swift
ne.prepend(0).toArray             // [0, 1, 2, 3]
ne.append(4).toArray              // [1, 2, 3, 4]
ne.append(contentsOf: [4, 5]).toArray  // [1, 2, 3, 4, 5]
ne.reversed.toArray               // [3, 2, 1]

ne[safe: 0]    // Optional(1)
ne[safe: 2]    // Optional(3)
ne[safe: 99]   // nil  — never crashes
ne[safe: -1]   // nil
```

---

## Semigroup (no Monoid)

`NonEmpty` can be combined — the result is always non-empty. There is no `identity` (no empty `NonEmpty` exists), so `NonEmpty` is a `Semigroup` but deliberately **not** a `Monoid`.

```swift
let a = nonEmpty(head: 1, tail: [2])
let b = nonEmpty(head: 3, tail: [4])

NonEmpty.combine(a, b).toArray  // [1, 2, 3, 4]
a <> b                          // [1, 2, 3, 4]  (with DataStructureOperators)

// sconcat — reduce a NonEmpty<A: Semigroup> to a single A
let nestedSemigroup = NonEmpty(head: nonEmpty(head: 1, tail: [2]), tail: [nonEmpty(head: 3)])
sconcat(nestedSemigroup).toArray  // [1, 2, 3]
```

---

## `<£>` and `<&>` — Map (Functor)

Transform every element; structure is preserved.

```swift
ne.map { $0 * 10 }.toArray    // [10, 20, 30]

// Operators (require DataStructureOperators)
let times10: @Sendable (Int) -> Int = { $0 * 10 }
times10 <£> ne       // [10, 20, 30]
ne <&> times10       // [10, 20, 30]

// Replace with constant
ne £> 0              // [0, 0, 0]
0 <£ ne              // [0, 0, 0]

// Point-free static form
let double = NonEmpty<Int>.fmap { (x: Int) in x * 2 }
double(ne).toArray   // [2, 4, 6]
```

**Functor laws:**
```swift-sketch
ne.map(id) == ne                                // identity
ne.map(compose(f, g)) == ne.map(f).map(g)       // composition
```

---

## `<*>` — Apply (Applicative)

Cartesian-product semantics: every function applied to every value.

```swift
// Lift into a singleton
NonEmpty<Int>.pure(42).toArray  // [42]

// Apply — cartesian product
let fns = NonEmpty<@Sendable (Int) -> Int>(head: { $0 + 1 }, tail: [{ $0 * 10 }])
NonEmpty.apply(fns, ne).toArray  // [2, 3, 4, 10, 20, 30]
fns <*> ne                       // same (with DataStructureOperators)

// Lift a binary function
NonEmpty.liftA2(+)(nonEmpty(head: 1, tail: [2]), nonEmpty(head: 10, tail: [20])).toArray
// [11, 21, 12, 22]

// Zip by index (shortest wins) — paired, not cartesian
NonEmpty.zip(nonEmpty(head: 1, tail: [2, 3]), nonEmpty(head: "a", tail: ["b"])).count  // 2

// Sequence — run both, keep one side
ne *> nonEmpty(head: "x", tail: ["y"])  // ["x", "y", "x", "y", "x", "y"]
ne <* nonEmpty(head: "x", tail: ["y"])  // [1, 1, 2, 2, 3, 3]
```

---

## `>>-` — FlatMap (Monad)

Map each element to a `NonEmpty`, then concatenate all results. The result is always non-empty.

```swift
ne.flatMap { n in NonEmpty(head: n, tail: [n * 10]) }.toArray
// [1, 10, 2, 20, 3, 30]

// Operator (requires DataStructureOperators)
ne >>- { n in NonEmpty(head: n, tail: [n * 10]) }

// Flatten nested NonEmpty
NonEmpty.join(nestedSemigroup).toArray  // [1, 2, 3]

// Kleisli composition
let plusOne: @Sendable (Int) -> NonEmpty<Int> = { NonEmpty(head: $0 + 1) }
let timesTwo: @Sendable (Int) -> NonEmpty<Int> = { NonEmpty(head: $0 * 2) }
let plusOneThenTwice = plusOne >=> timesTwo   // (3+1)*2 = 8
plusOneThenTwice(3).toArray                   // [8]
```

**Monad laws:**
```swift-sketch
NonEmpty.pure(x).flatMap(f) == f(x)                                // left identity
ne.flatMap(NonEmpty.pure) == ne                                    // right identity
ne.flatMap(f).flatMap(g) == ne.flatMap { f($0).flatMap(g) }        // associativity
```

---

## Fold (Foldable)

Reduce elements to a summary value.

```swift
ne.foldLeft(0, +)   // 6  — left fold: ((0+1)+2)+3
ne.foldRight(1, *)  // 6  — right fold: 1*(2*(3*1))

ne.foldMap { Int.Monoids.Sum($0) }.rawValue  // 6
ne.toList   // [1, 2, 3]  — standard [A]
```

---

## Traverse (Traversable)

Map elements to a container and flip the nesting. Short-circuits on the first failure.

```swift
enum ParseError: Error, Sendable, Equatable { case badInput }

let strings = nonEmpty(head: "1", tail: ["2", "3"])

// Optional effect
strings.traverse { Int($0) }?.toArray                       // [1, 2, 3]
nonEmpty(head: "1", tail: ["x"]).traverse { Int($0) }       // nil

// Result effect
strings.traverse { s -> Result<Int, ParseError> in
    Int(s).map { .success($0) } ?? .failure(.badInput)
}
// .success(NonEmpty(head: 1, tail: [2, 3]))

// sequence — flip without mapping
NonEmpty<Int?>(head: 1, tail: [2, 3]).sequence()?.toArray  // [1, 2, 3]
NonEmpty<Int?>(head: 1, tail: [nil]).sequence()            // nil
```

---

## Transformer: `NonEmptyTOptional` (wraps `NonEmpty<A?>`)

Map or flatMap over the present values while preserving `nil` slots in place. Lift with `.nonEmptyT` (or `NonEmptyTOptional(ne)`), leave with `.rawValue`.

```swift
let slots = NonEmpty<Int?>(head: 1, tail: [nil, 3])

// map: only over present values
slots.nonEmptyT.map { $0 * 10 }.rawValue.toArray      // [Optional(10), nil, Optional(30)]

// flatMap: the continuation returns the whole stack (NonEmptyTOptional<B>);
//          nil slots stay nil in the result, present slots follow the function
slots.nonEmptyT.flatMap { n in NonEmptyTOptional(NonEmpty<Int?>(head: n * 2)) }.rawValue.toArray
// [Optional(2), nil, Optional(6)]
```

---

## Transformer: `NonEmptyTResult` (wraps `NonEmpty<Result<A, E>>`)

Map or flatMap over success values while preserving failures in place. Generic order is `NonEmptyTResult<E, A>`.

```swift
enum SlotError: Error, Sendable, Equatable { case err }

let results = NonEmpty<Result<Int, SlotError>>(
    head: .success(1),
    tail: [.failure(.err), .success(3)]
)

// map: over success values
results.nonEmptyT.map { $0 * 10 }.rawValue.toArray
// [.success(10), .failure(.err), .success(30)]

// flatMap: the continuation returns NonEmptyTResult<E, B>;
//          failures propagate, successes follow the function
results.nonEmptyT.flatMap { n in NonEmptyTResult(NonEmpty<Result<Int, SlotError>>(head: .success(n * 2))) }.rawValue.toArray
// [.success(2), .failure(.err), .success(6)]
```

---

## Transformer: `OptionalTNonEmpty` (wraps `NonEmpty<A>?`)

`Optional<NonEmpty<A>>`, when the whole collection may be absent. Lift with `.optionalT`.

```swift

// map: inside when present
opt.optionalT.map { $0 * 10 }.rawValue?.toArray  // [10, 20, 30]
OptionalTNonEmpty<Int>(nil).map { $0 * 10 }.rawValue  // nil

// flatMap: element-level Optional; nils are dropped
opt.optionalT.flatMap { n in
    OptionalTNonEmpty(n > 1 ? NonEmpty(head: n * 10) : nil)
}.rawValue?.toArray  // [20, 30]   (1 → nil, dropped; 2 → 20; 3 → 30)
```

The escape hatches are `mapMaybeT` (`NonEmptyTOptional`), `mapExceptT` (`NonEmptyTResult`, `NonEmptyTEither`) and `mapOptionalT` (`OptionalTNonEmpty`). `NonEmpty` is also the inner layer of `EitherTNonEmpty`, `ReaderTNonEmpty`, `StatefulTNonEmpty`, `ValidationTNonEmpty` and `WriterTNonEmpty`, see [MonadTransformers](../fp/monadtransformers).

---

## Equatable, Comparable, Hashable

`NonEmpty<A>` is `Equatable` when `A: Equatable`, `Comparable` when `A: Comparable`, and `Hashable` when `A: Hashable`. Comparison delegates to the underlying `Array`.

```swift
NonEmpty(head: 1, tail: [2]) == NonEmpty(head: 1, tail: [2])  // true
NonEmpty(head: 1, tail: [2]) <  NonEmpty(head: 1, tail: [3])  // true
NonEmpty(head: 2)            >  NonEmpty(head: 1, tail: [9])  // true (head wins)
```

---

## Module

`NonEmpty<A>` lives in the `DataStructure` module. Operator overloads (`<£>`, `>>-`, `<>`, …) are in `DataStructureOperators`.

```swift-sketch
import DataStructure             // named functions only
import DataStructureOperators    // adds <£>, <&>, >>-, <=<, <>, …
import FP                        // re-exports both + CoreFP + CoreFPOperators
```

---

## For Haskell developers

`NonEmpty<A>` is one of the closest 1:1 mappings in this library — it is the same idea as `Data.List.NonEmpty`'s `NonEmpty a` in `base`, right down to the head/tail split.

| This library | Haskell (`Data.List.NonEmpty`, `base`) |
|---|---|
| `NonEmpty<A>` | `NonEmpty a` |
| `NonEmpty(head:tail:)` | `:\|` constructor (`a :\| [a]`) |
| `.head` | `head` (record field, via `NonEmpty.Internal`) |
| `.tail` | `tail` |
| `nonEmpty(_:)` (`[A] -> NonEmpty<A>?`) | `nonEmpty :: [a] -> Maybe (NonEmpty a)` |
| `.toArray` / `.toList` | `toList` |
| `<>` / `.combine` (Semigroup, no Monoid) | `<>` (`Semigroup`, also no `Monoid` instance — same reasoning: no empty identity) |
| `sconcat` | `sconcat` |
| `<£>` / `.map` (Functor) | `fmap` / `<$>` |
| `<*>` / `.apply` / `.liftA2` (Applicative, cartesian) | `<*>` / `liftA2` |
| `>>-` / `.flatMap` (Monad) | `>>=` |
| `>=>` | `>=>` |
| `.foldLeft` / `.foldRight` / `.foldMap` | `foldl'` / `foldr` / `foldMap` (via `Foldable1`) |
| `.traverse` / `.sequence` | `traverse` / `sequence` (via `Traversable`) |
| `extract(_:)` | `extract` (`Comonad`) |
| `.extend` / `.coflatMap` | `extend` / `=>>` (`Comonad`) |
| `duplicate(_:)` | `duplicate` (`Comonad`) |

The one gap: `base` does not ship a `Comonad` instance for `NonEmpty` — that lives in the ecosystem, not the standard library. The `comonad` package (via `semigroupoids`'s `Foldable1`/`Traversable1` machinery) is what supplies `extract`/`duplicate`/`extend` for `NonEmpty` in idiomatic Haskell code, which is the closest real analog to the `extract`/`.extend`/`duplicate` trio this library ships.

**References:**
- [`Data.List.NonEmpty`](https://hackage.haskell.org/package/base/docs/Data-List-NonEmpty.html) (`base`)
- [`comonad`](https://hackage.haskell.org/package/comonad) — supplies the `Comonad NonEmpty` instance `base` omits
