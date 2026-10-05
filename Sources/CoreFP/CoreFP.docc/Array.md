# ``Swift/Array``

Swift's `Array` extended with functional operators and named functions.

Array as a monad models **non-determinism** — a computation that can return multiple possible results. `fmap` transforms each element, `apply` produces all combinations of functions and values, and `bind` flatMaps over all results.

---

## `<£>` and `<&>` — Map

Apply a function to every element. `<£>` puts the function on the left; `<&>` puts the array on the left.

```swift
let m1 = ({ $0 * 2 } <£> [1, 2, 3])          // [2, 4, 6]
let m2 = ({ "\($0)" } <£> [1, 2, 3])         // ["1", "2", "3"]

let m3 = [1, 2, 3] <&> { $0 * 2 }            // [2, 4, 6]

// Named function
let m4 = Array.fmap { $0 * 2 }([1, 2, 3])    // [2, 4, 6]
let m5 = [1, 2, 3].map { $0 * 2 }            // [2, 4, 6]
```

---

## `£>` and `<£` — Replace

Replace every element with a constant.

```swift
let c1 = [1, 2, 3] £> "x"   // ["x", "x", "x"]
let c2 = "x" <£ [1, 2, 3]   // ["x", "x", "x"]

// Named function
let c3 = Array.fmap(const("x"))([1, 2, 3])  // ["x", "x", "x"]
```

---

## `<*>` — Apply

Apply each function to each value — cartesian product of functions × values.

```swift
let addOne: @Sendable (Int) -> Int = { $0 + 1 }
let timesTen: @Sendable (Int) -> Int = { $0 * 10 }

let a1 = [addOne, timesTen] <*> [1, 2, 3]   // [2, 3, 4, 10, 20, 30]
let a2 = [addOne] <*> ([] as [Int])         // []

// Named function
let a3 = Array.apply([addOne, timesTen], [1, 2, 3])  // [2, 3, 4, 10, 20, 30]

// liftA2: lift a binary function to work on all pairs
let a4 = Array.liftA2(+)([1, 2], [10, 20])  // [11, 21, 12, 22]
```

---

## `*>` and `<*` — Sequence

Cartesian product, discarding one side's values.

```swift
let s1 = [1, 2] *> ["a", "b"]            // ["a", "b", "a", "b"]  (2 × 2, keeping right)
let s2 = [1, 2] <* ["a", "b"]            // [1, 1, 2, 2]           (2 × 2, keeping left)
let s3 = ([] as [Int]) *> ["a", "b"]     // []

// Named functions
let s4 = [1, 2].seqRight(["a", "b"])  // ["a", "b", "a", "b"]
let s5 = [1, 2].seqLeft(["a", "b"])   // [1, 1, 2, 2]
```

---

## `>>-` and `-<<` — Bind (flatMap)

Apply a function to each element and flatten the results. `>>-` puts the array on the left; `-<<` puts the function on the left.

```swift
let withTens: @Sendable (Int) -> [Int] = { [$0, $0 * 10] }
let onlyEven: @Sendable (Int) -> [Int] = { $0 % 2 == 0 ? [$0] : [] }

let b1 = [1, 2, 3] >>- withTens       // [1, 10, 2, 20, 3, 30]
let b2 = [1, 2, 3] >>- onlyEven       // [2]  (filter-like)

let b3 = withTens -<< [1, 2, 3]       // [1, 10, 2, 20, 3, 30]

// Named function
let b4 = Array.bind(withTens)([1, 2, 3])  // [1, 10, 2, 20, 3, 30]
let b5 = [1, 2, 3].flatMap { [$0, $0 * 10] }  // [1, 10, 2, 20, 3, 30]
```

---

## `>=>` — Kleisli composition

Compose two functions that each return an array.

```swift
let expand: @Sendable (Int) -> [Int] = { [$0, $0 + 1] }
let doubled: @Sendable (Int) -> [Int] = { [$0 * 2] }

let kleisliPipeline = expand >=> doubled
let k1 = kleisliPipeline(3)   // [6, 8]  — expand gives [3,4], doubled gives [6] and [8]

// Named function
let k2 = Array.kleisli(expand, doubled)(3)  // [6, 8]
```

---

## `<|>` — Alternative (concatenation)

Concatenate two arrays.

```swift
let alt1 = [1, 2] <|> [3, 4]            // [1, 2, 3, 4]
let alt2 = ([] as [Int]) <|> [1, 2]     // [1, 2]
```

---

## `filterM` — curried filter

A curried version of `filter` for point-free composition:

```swift
let f1 = Array.filterM { (n: Int) in n > 2 }([1, 2, 3, 4])   // [3, 4]

// Useful in pipelines
let keepPositives = Array.filterM { (n: Int) in n > 0 }
let f2 = keepPositives([1, -2, 3, -4])   // [1, 3]

// The function filterM returns is not @Sendable, so it can't feed `>>>`; apply it instead
let keepBig = Array.filterM { (n: Int) in n > 4 }
let f3 = keepBig(Array.fmap { (n: Int) in n * 2 }([1, 2, 3, 4]))   // [6, 8]
```

---

## Fold (Foldable)

### `foldLeft` — left-associative fold

Accumulates from left to right:

```swift
Array.foldLeft(0, +)([1, 2, 3, 4])    // 10   — (((0+1)+2)+3)+4
Array.foldLeft(1, *)([1, 2, 3, 4])    // 24   — (((1*1)*2)*3)*4
Array.foldLeft("", { $0 + $1 })(["a", "b", "c"])  // "abc"

// Curried — useful for composition
let sum = Array.foldLeft(0, +)
sum([1, 2, 3])   // 6
```

### `foldRight` — right-associative fold

Accumulates from right to left:

```swift
Array.foldRight(-, 0)([1, 2, 3])    // 2    — 1-(2-(3-0))
Array.foldRight({ $1 + [$0] }, [])([1, 2, 3])  // [3, 2, 1]  — reverse

// foldRight is lazy — useful for short-circuiting operations
let firstPositive = Array.foldRight(
    { elem, acc in elem > 0 ? elem : acc },
    0
)
firstPositive([0, -1, 5, 2])   // 5
```

### `foldMap` — map to a Monoid, then combine

```swift
Array.foldMap { Int.Monoids.Sum($0) }([1, 2, 3])       // Sum(6)
Array.foldMap { Int.Monoids.Product($0) }([2, 3, 4])   // Product(24)

// Combine strings
Array.foldMap { [$0 * 2] }([1, 2, 3])   // [2, 4, 6]  — Array<[Int]> folded into [Int]

// Curried — useful in composition
let sumAll = Array.foldMap { Int.Monoids.Sum($0) }
sumAll([10, 20, 30]).rawValue   // 60
```

---

## Traverse

Useful for **inverting nested structures** — turning an array of optionals or results into a single optional or result wrapping an array.

```swift
// sequence :: [a?] -> [a]?   — Array<Optional> into Optional<Array>
// All elements must be non-nil; one nil collapses the whole result
let q3 = [Optional(1), Optional(2), Optional(3)].sequence()  // Optional([1, 2, 3])
let q4 = [Optional(1), nil, Optional(3)].sequence()          // nil

// traverse :: (a -> b?) -> [a] -> [b]?
let q5 = ["1", "2", "3"].traverse { Int($0) }   // Optional([1, 2, 3])
let q6 = ["1", "??", "3"].traverse { Int($0) }  // nil

// sequence :: [Result<a,e>] -> Result<[a],e>   — Array<Result> into Result<Array>
enum MyError: Error { case err, bad }

let okResults: [Result<Int, MyError>] = [.success(1), .success(2)]
let badResults: [Result<Int, MyError>] = [.success(1), .failure(.err), .success(3)]
let q1: Result<[Int], MyError> = okResults.sequence()    // .success([1, 2])
let q2: Result<[Int], MyError> = badResults.sequence()   // .failure(.err)

// sequence :: [[a]] -> [[a]]   — cartesian product (Array<Array> into Array<Array>)
let q7 = [[1, 2], [3, 4]].sequence()   // [[1, 3], [1, 4], [2, 3], [2, 4]]
```

---

## Monad Transformers

Array can be the **outer** layer of a transformer stack. Each stack is its own struct named
`ArrayT{Inner}`, wrapping the nested array: lift with the `.arrayT` property (or `ArrayTOptional(xs)`),
work with `map` / `flatMap` / the usual operators, and leave with `.rawValue`. A bare `[Int?]` is
just an array, its `map` and `<£>` see `Int?`; the stack is what reaches the `Int`.

### `ArrayTOptional` (`[A?]`)

Array of Optional values. `nil` elements stay `nil`; `some` elements are transformed.

```swift
import FP

let xs: [Int?] = [1, nil, 3]

// map: transform non-nil elements, leave nil elements as nil
xs.arrayT.map { $0 * 2 }.rawValue   // [Optional(2), nil, Optional(6)]

// apply: cartesian product with optional apply at each pair
let double: @Sendable (Int) -> Int = { $0 * 2 }
let fns = ArrayTOptional<@Sendable (Int) -> Int>([double, nil])
ArrayTOptional<Int>.apply(fns, ArrayTOptional([3, 4])).rawValue
// [Optional(6), Optional(8), nil, nil]

// flatMap: nil → [nil], some(a) → fn(a)
xs.arrayT.flatMap { n in ArrayTOptional([n, n + 1]) }.rawValue
// [Optional(1), Optional(2), nil, Optional(3), Optional(4)]

// Operators
let opMapped = ({ $0 * 2 } <£> xs.arrayT).rawValue  // [Optional(2), nil, Optional(6)]
let opBound = xs.arrayT >>- { n in ArrayTOptional([n, nil]) }

// Escape hatch (Haskell's mapMaybeT): the whole [Int?]
let reversedAll = xs.arrayT.mapMaybeT { Array($0.reversed()) }
```

### `ArrayTResult` (`[Result<A, E>]`)

Array of Result values. `.failure` elements propagate; `.success` elements are transformed.

```swift
import FP

let rs: [Result<Int, MyError>] = [.success(1), .failure(.bad), .success(3)]
rs.arrayT.map { $0 * 2 }.rawValue   // [.success(2), .failure(.bad), .success(6)]

// flatMap: .failure → [.failure(e)], .success(a) → fn(a)
rs.arrayT.flatMap { n in ArrayTResult([.success(n), .success(n * 10)]) }.rawValue
// [.success(1), .success(10), .failure(.bad), .success(3), .success(30)]

// Operators
let rsMapped = { $0 * 2 } <£> rs.arrayT            // ArrayTResult wrapping [.success(2), .failure(.bad), .success(6)]
let rsBound = rs.arrayT >>- { n in .pure(n * 2) }
```

### `ArrayTEither` (`[Either<L, A>]`)

Array of Either values. `.left` elements propagate; `.right` elements are transformed.

```swift
import DataStructure
import DataStructureOperators

let es: [Either<String, Int>] = [.right(1), .left("err"), .right(3)]
es.arrayT.map { $0 * 2 }.rawValue   // [.right(2), .left("err"), .right(6)]

// flatMap: .left(l) → [.left(l)], .right(a) → fn(a)
es.arrayT.flatMap { n in ArrayTEither([.right(n), .right(n * 10)]) }.rawValue
// [.right(1), .right(10), .left("err"), .right(3), .right(30)]

// Operators
let esMapped = { $0 * 2 } <£> es.arrayT            // ArrayTEither wrapping [.right(2), .left("err"), .right(6)]
let esBound = es.arrayT >>- { n in .pure(n * 2) }
```

The other Array-outer stacks are `ArrayTWriter` (`[Writer<W, A>]`, a lawful `WriterT` over the list)
and `ArrayTStateful` (`[Stateful<S, A>]`, functor and applicative only); both live in
`DataStructure`.

---

## Module

```swift
import FP        // Named functions (fmap, apply, seqRight, bind, kleisli…) and ArrayTOptional / ArrayTResult
import CoreFPOperators  // Operators (<£>, <*>, >>-, >=>…)

// For ArrayTEither / ArrayTWriter / ArrayTStateful:
import DataStructure
import DataStructureOperators
```

---

## For Haskell developers

| This library | Haskell equivalent |
|---|---|
| `[A]` | `[a]` / `Data.List` |
| `<£>` / `<&>` (`fmap`) | `fmap` / `<$>` |
| `<*>` | `Control.Applicative`'s list `<*>` — cartesian product of functions × values |
| `liftA2` | `Control.Applicative`'s `liftA2` |
| `>>-` / `-<<` (`flatMap`) | `>>=` / `=<<` (the list monad) |
| `>=>` | `Control.Monad`'s `>=>` |
| `<|>` | `Alternative`'s `<|>` for `[]` (list concatenation, same as `<>`/`mplus`) |
| `filterM` | **name collision, not the same function** — this library's `filterM` is just a curried `filter`; Haskell's `Control.Monad.filterM` is the monadic power-set-style filter, `(a -> m Bool) -> [a] -> m [a]` |
| `foldLeft` | `Data.List`'s `foldl'` |
| `foldRight` | `Data.List`'s `foldr` |
| `foldMap` | `Data.Foldable`'s `foldMap` |
| `sequence` / `traverse` | `Data.Traversable`'s `sequence` / `traverse` (`sequenceA`) |

External references:
- [`Data.List`](https://hackage.haskell.org/package/base/docs/Data-List.html) — Haskell's base module for list operations
- [`Data.Traversable`](https://hackage.haskell.org/package/base/docs/Data-Traversable.html) — defines `traverse` and `sequenceA`
