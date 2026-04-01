import FP

// ============================================================
// FOLDABLE
// foldLeft  :: b -> (b -> a -> b) -> f a -> b
// foldRight :: (a -> b -> b) -> b -> f a -> b
// foldMap   :: Monoid m => (a -> m) -> f a -> m
//
// Foldable is the typeclass for structures that can be reduced
// to a summary value. foldLeft processes elements left-to-right
// (strict, efficient for most uses). foldRight processes
// right-to-left (important for laziness and list construction).
// foldMap maps each element to a Monoid, then combines.
// ============================================================

// MARK: - Array / foldLeft

// let nums = [1, 2, 3, 4, 5]

// --- Named function (curried: initial -> combiner -> array -> result) ---
// Array<Int>.foldLeft(0, +)(nums)           // 15 — sum
// Array<Int>.foldLeft(1, *)(nums)           // 120 — product
// Array<Int>.foldLeft("", { acc, n in acc + "\(n)" })(nums)  // "12345"

// --- Compute max without using max() ---
// Array<Int>.foldLeft(Int.min, Swift.max)(nums)  // 5

// --- Build a reversed array ---
// Array<Int>.foldLeft([]) { acc, x in [x] + acc }(nums)  // [5, 4, 3, 2, 1]


// MARK: - Array / foldRight

// let nums = [1, 2, 3, 4, 5]

// --- Named function (curried: combiner -> initial -> array -> result) ---
// Array<Int>.foldRight(+, 0)(nums)          // 15 — same as foldLeft for + (associative)
// Array<Int>.foldRight({ x, acc in [x] + acc }, [])(nums)  // [1, 2, 3, 4, 5] — id for list

// --- foldRight naturally builds lists (prepend = correct order) ---
// Array<Int>.foldRight({ x, acc in [x * 2] + acc }, [])(nums)  // [2, 4, 6, 8, 10]

// --- The difference: foldLeft reverses, foldRight preserves ---
// let consLeft  = Array<Int>.foldLeft([])  { acc, x in acc + [x] }(nums)   // [1,2,3,4,5]
// let consRight = Array<Int>.foldRight({ x, acc in [x] + acc }, [])(nums)  // [1,2,3,4,5]


// MARK: - Array / foldMap

// foldMap maps each element to a Monoid, then folds via mconcat.
// The Monoid determines what "combining" means.

// --- Count elements (using Int as additive Monoid via Array.count approach) ---
// let nums = [1, 2, 3, 4, 5]

// --- Map to strings and concatenate ---
// Array<Int>.foldMap { "\($0)" }(nums)      // "12345" — String is a Semigroup

// --- Check if any element satisfies a predicate using Endo ---
// let positives: [Int] = [-1, 2, -3, 4, 5]
// // Count positive numbers:
// Array<Int>.foldMap { n in [n] }.filter { $0 > 0 }(positives)  // isn't quite right
// // Better: map to Int.Monoids.Sum to count
// Array<Int>.foldMap { n -> Int in n > 0 ? 1 : 0 }(positives)  // 3

// --- Using Endo: chain transformations from a list of functions ---
// let transforms: [(Int) -> Int] = [{ $0 + 1 }, { $0 * 2 }, { $0 - 3 }]
// let combined = Array.foldMap(Endo.init)(transforms)
// combined.runEndo(5)                       // ((5 + 1) * 2) - 3 = 9


// MARK: - Optional (also Foldable)
// Optional can be folded: .none contributes nothing, .some contributes one element.

// let x: Int? = .some(5)
// let none: Int? = .none

// --- Use Optional's toList to convert to Array then fold ---
// let asArray: [Int] = x.map { [$0] } ?? []    // [5]
// let noneArr: [Int] = none.map { [$0] } ?? []  // []

// --- Fold over Optional using withDefault ---
// x.withDefault(0)                          // 5
// none.withDefault(0)                       // 0

// --- foldMap on Optional: contribute to a Monoid if present ---
// x.map { "\($0)" } ?? ""                   // "5"
// none.map { "\($0)" } ?? ""                // ""

//: [Previous](@previous) | [Next](@next)
