import FP

// ============================================================
// NONEMPTY<A>
//
// NonEmpty<A> is a sequence guaranteed to contain at least one
// element. It has a head (guaranteed) and a tail ([A]).
//
// Key property: it is a Semigroup but NOT a Monoid.
// Two non-empty sequences always combine into a non-empty one,
// but there is no empty value — the identity element doesn't exist.
// Therefore: use sconcat (not mconcat) when folding.
//
// Functor, Applicative, and Monad instances are available.
// ============================================================

// MARK: - Construction

// --- Direct init ---
// let digits = NonEmpty(head: 1, tail: [2, 3, 4])   // NonEmpty<Int>
// let single = NonEmpty(head: "only")                // NonEmpty<String>

// --- Free function constructors ---
// let nums = nonEmpty(head: 1, tail: [2, 3])         // NonEmpty<Int>

// --- From Array (returns Optional — the array might be empty) ---
// let fromArr: NonEmpty<Int>? = nonEmpty([1, 2, 3])  // .some(NonEmpty(1, [2, 3]))
// let fromEmpty: NonEmpty<Int>? = nonEmpty([])       // .none — type-safe!


// MARK: - Properties

// let ne = NonEmpty(head: 1, tail: [2, 3, 4, 5])

// ne.head                                  // 1 — always exists, never optional
// ne.tail                                  // [2, 3, 4, 5]
// ne.last                                  // 5
// ne.count                                 // 5
// ne.toArray                               // [1, 2, 3, 4, 5]
// ne.description                           // "NonEmpty([1, 2, 3, 4, 5])"


// MARK: - Functor

// let ne = NonEmpty(head: 1, tail: [2, 3])

// --- Named function ---
// ne.map { $0 * 2 }                        // NonEmpty(head: 2, tail: [4, 6])

// --- Operators ---
// { $0 * 2 } <£> ne                        // NonEmpty(head: 2, tail: [4, 6])
// ne <&> { $0 * 2 }                        // NonEmpty(head: 2, tail: [4, 6])
// ne £> 0                                  // NonEmpty(head: 0, tail: [0, 0])


// MARK: - Applicative

// let ne = NonEmpty(head: 1, tail: [2, 3])
// let fns = NonEmpty(head: { (x: Int) in x + 10 }, tail: [{ $0 * 2 }])

// --- apply: each function applied to each value (cartesian product) ---
// fns <*> ne                               // NonEmpty(11, [12, 13, 2, 4, 6])

// --- liftA2 ---
// let ne2 = NonEmpty(head: 10, tail: [20])
// NonEmpty<Int>.liftA2(+)(ne, ne2)         // NonEmpty(11, [21, 12, 22, 13, 23])


// MARK: - Monad

// let ne = NonEmpty(head: 1, tail: [2, 3])

// --- flatMap: expand each element, flatten into NonEmpty ---
// ne.flatMap { n in NonEmpty(head: n, tail: [n * 10]) }
// // NonEmpty(head: 1, tail: [10, 2, 20, 3, 30])

// --- bind (curried) ---
// let expand: (Int) -> NonEmpty<Int> = { n in NonEmpty(head: n, tail: [-n]) }
// NonEmpty<Int>.bind(expand)(ne)           // NonEmpty(1, [-1, 2, -2, 3, -3])
// ne >>- expand                           // NonEmpty(1, [-1, 2, -2, 3, -3])


// MARK: - Semigroup (but NOT Monoid — no empty value)

// let a = NonEmpty(head: 1, tail: [2, 3])
// let b = NonEmpty(head: 4, tail: [5])
// let c = NonEmpty(head: 6, tail: [])

// --- combine (Semigroup) ---
// NonEmpty.combine(a, b)                   // NonEmpty(1, [2, 3, 4, 5])
// a <> b                                   // NonEmpty(1, [2, 3, 4, 5])

// --- sconcat (fold non-empty list via Semigroup) ---
// sconcat(a, [b, c])                       // NonEmpty(1, [2, 3, 4, 5, 6])
// // Note: mconcat is NOT available for NonEmpty — there's no identity element


// MARK: - Practical: guarantee non-empty input

// func process(_ items: NonEmpty<String>) -> String {
//     "Processing \(items.count) items, starting with: \(items.head)"
// }

// --- Safe: only call if we know we have items ---
// if let items = nonEmpty(["apple", "banana", "cherry"]) {
//     process(items)                        // "Processing 3 items, starting with: apple"
// }

// --- The head is always safe to access — no Optional unwrapping needed ---
// let firstItem: String = items.head       // guaranteed, no ?

//: [Previous](@previous) | [Next](@next)
