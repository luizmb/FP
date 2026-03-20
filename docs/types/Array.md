# Array

Swift's `Array` extended with functional operators and named functions.

Array as a monad models **non-determinism** — a computation that can return multiple possible results. `fmap` transforms each element, `apply` produces all combinations of functions and values, and `bind` flatMaps over all results.

---

## `<£>` and `<&>` — Map

Apply a function to every element. `<£>` puts the function on the left; `<&>` puts the array on the left.

```swift
{ $0 * 2 } <£> [1, 2, 3]          // [2, 4, 6]
{ "\($0)" } <£> [1, 2, 3]         // ["1", "2", "3"]

[1, 2, 3] <&> { $0 * 2 }          // [2, 4, 6]

// Named function
Array.fmap { $0 * 2 }([1, 2, 3])  // [2, 4, 6]
[1, 2, 3].map { $0 * 2 }          // [2, 4, 6]
```

---

## `£>` and `<£` — Replace

Replace every element with a constant.

```swift
[1, 2, 3] £> "x"   // ["x", "x", "x"]
"x" <£ [1, 2, 3]   // ["x", "x", "x"]

// Named function
Array.fmap(const("x"))([1, 2, 3])  // ["x", "x", "x"]
```

---

## `<*>` — Apply

Apply each function to each value — cartesian product of functions × values.

```swift
[{ $0 + 1 }, { $0 * 10 }] <*> [1, 2, 3]   // [2, 3, 4, 10, 20, 30]
[{ $0 + 1 }] <*> []                          // []

// Named function
Array.apply([{ $0 + 1 }, { $0 * 10 }], [1, 2, 3])  // [2, 3, 4, 10, 20, 30]

// liftA2 — lift a binary function to work on all pairs
Array.liftA2(+)([1, 2], [10, 20])  // [11, 21, 12, 22]
```

---

## `*>` and `<*` — Sequence

Cartesian product, discarding one side's values.

```swift
[1, 2] *> ["a", "b"]   // ["a", "b", "a", "b"]  (2 × 2, keeping right)
[1, 2] <* ["a", "b"]   // [1, 1, 2, 2]           (2 × 2, keeping left)
[]     *> ["a", "b"]   // []

// Named functions
[1, 2].seqRight(["a", "b"])  // ["a", "b", "a", "b"]
[1, 2].seqLeft(["a", "b"])   // [1, 1, 2, 2]
```

---

## `>>-` and `-<<` — Bind (flatMap)

Apply a function to each element and flatten the results. `>>-` puts the array on the left; `-<<` puts the function on the left.

```swift
[1, 2, 3] >>- { [$0, $0 * 10] }             // [1, 10, 2, 20, 3, 30]
[1, 2, 3] >>- { $0 % 2 == 0 ? [$0] : [] }   // [2]  (filter-like)

{ [$0, $0 * 10] } -<< [1, 2, 3]             // [1, 10, 2, 20, 3, 30]

// Named function
Array.bind { [$0, $0 * 10] }([1, 2, 3])  // [1, 10, 2, 20, 3, 30]
[1, 2, 3].flatMap { [$0, $0 * 10] }      // [1, 10, 2, 20, 3, 30]
```

---

## `>=>` — Kleisli composition

Compose two functions that each return an array.

```swift
let expand:  (Int) -> [Int] = { [$0, $0 + 1] }
let doubled: (Int) -> [Int] = { [$0 * 2] }

let pipeline = expand >=> doubled
pipeline(3)   // [6, 8]  — expand gives [3,4], doubled gives [6] and [8]

// Named function
Array.kleisli(expand, doubled)(3)  // [6, 8]
```

---

## `<|>` — Alternative (concatenation)

Concatenate two arrays.

```swift
[1, 2] <|> [3, 4]   // [1, 2, 3, 4]
[]     <|> [1, 2]   // [1, 2]
```

---

## Traverse

Useful for **inverting nested structures** — turning an array of optionals or results into a single optional or result wrapping an array.

```swift
// sequence :: [a?] -> [a]?   — Array<Optional> into Optional<Array>
// All elements must be non-nil; one nil collapses the whole result
[Optional(1), Optional(2), Optional(3)].sequence()  // Optional([1, 2, 3])
[Optional(1), nil, Optional(3)].sequence()          // nil

// traverse :: (a -> b?) -> [a] -> [b]?
["1", "2", "3"].traverse { Int($0) }   // Optional([1, 2, 3])
["1", "??", "3"].traverse { Int($0) }  // nil

// sequence :: [Result<a,e>] -> Result<[a],e>   — Array<Result> into Result<Array>
[Result<Int, MyError>.success(1), .success(2)].sequence()           // .success([1, 2])
[Result<Int, MyError>.success(1), .failure(.err), .success(3)].sequence()  // .failure(.err)

// sequence :: [[a]] -> [[a]]   — cartesian product (Array<Array> into Array<Array>)
[[1, 2], [3, 4]].sequence()   // [[1, 3], [1, 4], [2, 3], [2, 4]]
```

---

## Monad Transformers

Array can be the **outer** layer of a transformer stack. The transformer name is `ArrayT{Inner}`.

### `ArrayTOptional` — `[A?]`

Array of Optional values. `nil` elements stay `nil`; `some` elements are transformed.

```swift
import FP

// mapT — transform non-nil elements, leave nil elements as nil
let xs: [Int?] = [1, nil, 3]
xs.mapT { $0 * 2 }              // [Optional(2), nil, Optional(6)]

// applyArrayOptional — cartesian product with optional apply at each pair
applyArrayOptional([Optional({ $0 * 2 }), nil], [Optional(3), Optional(4)])
// [Optional(6), Optional(8), nil, nil]

// flatMapT — nil → [nil], some(a) → fn(a)
xs.flatMapT { n in [n, n + 1] }
// [Optional(1), Optional(2), nil, Optional(3), Optional(4)]

// Operators
{ $0 * 2 } <£> xs               // [Optional(2), nil, Optional(6)]
xs >>- { n in [Optional(n), nil] }
```

### `ArrayTResult` — `[Result<A,E>]`

Array of Result values. `.failure` elements propagate; `.success` elements are transformed.

```swift
import FP

let rs: [Result<Int, MyError>] = [.success(1), .failure(.bad), .success(3)]
rs.mapT { $0 * 2 }              // [.success(2), .failure(.bad), .success(6)]

// flatMapT — .failure → [.failure(e)], .success(a) → fn(a)
rs.flatMapT { n in [.success(n), .success(n * 10)] }
// [.success(1), .success(10), .failure(.bad), .success(3), .success(30)]

// Operators
{ $0 * 2 } <£> rs               // [.success(2), .failure(.bad), .success(6)]
rs >>- { n in [.success(n * 2)] }
```

### `ArrayTEither` — `[Either<L,A>]`

Array of Either values. `.left` elements propagate; `.right` elements are transformed.

```swift
import Either

let es: [Either<String, Int>] = [.right(1), .left("err"), .right(3)]
es.mapT { $0 * 2 }              // [.right(2), .left("err"), .right(6)]

// flatMapT — .left(l) → [.left(l)], .right(a) → fn(a)
es.flatMapT { n in [.right(n), .right(n * 10)] }
// [.right(1), .right(10), .left("err"), .right(3), .right(30)]

// Operators (EitherOperators)
{ $0 * 2 } <£> es               // [.right(2), .left("err"), .right(6)]
es >>- { n in [.right(n * 2)] }
```

---

## Module

```swift
import FP        // Named functions (fmap, apply, seqRight, bind, kleisli…)
import Operators  // Operators (<£>, <*>, >>-, >=>…)

// For Either-inner transformers:
import Either
import EitherOperators
```
