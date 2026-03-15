# Array

Swift's `Array` extended with functional operators and named functions.

Array as a monad models **non-determinism** — a computation that can return multiple possible results. `fmap` transforms each element, `apply` produces all combinations of functions and values, and `bind` flatMaps over all results.

---

## `<£>` — Map

Apply a function to every element.

```swift
{ $0 * 2 } <£> [1, 2, 3]          // [2, 4, 6]
{ "\($0)" } <£> [1, 2, 3]         // ["1", "2", "3"]

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

## `<&>` — Flipped map

Same as `<£>` with the array on the left.

```swift
[1, 2, 3] <&> { $0 * 2 }   // [2, 4, 6]
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

## `>>-` — Bind (flatMap)

Apply a function to each element and flatten the results. Models non-deterministic branching.

```swift
[1, 2, 3] >>- { [$0, $0 * 10] }        // [1, 10, 2, 20, 3, 30]
[1, 2, 3] >>- { $0 % 2 == 0 ? [$0] : [] }  // [2]  (filter-like)

// Named function
Array.bind { [$0, $0 * 10] }([1, 2, 3])  // [1, 10, 2, 20, 3, 30]
[1, 2, 3].flatMap { [$0, $0 * 10] }      // [1, 10, 2, 20, 3, 30]
```

---

## `-<<` — Flipped bind

Same as `>>-` with arguments reversed.

```swift
{ [$0, $0 * 10] } -<< [1, 2, 3]   // [1, 10, 2, 20, 3, 30]
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

## Module

```swift
import FP       // Named functions (fmap, apply, seqRight, bind, kleisli…)
import Operators // Operators (<£>, <*>, >>-, >=>…)
```
