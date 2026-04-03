import FP

// ============================================================
// NONEMPTY<A>
//
// A sequence guaranteed to have at least one element.
// Semigroup but NOT Monoid — no empty value exists.
// Use sconcat (not mconcat) when folding a list of them.
// ============================================================

// MARK: - Construction

func nonEmptyConstruction() {
    // Direct init
    let digits = NonEmpty(head: 1, tail: [2, 3, 4])
    let single = NonEmpty(head: "only")

    digits   // NonEmpty([1, 2, 3, 4])
    single   // NonEmpty(["only"])

    // Free function constructors
    let nums = nonEmpty(head: 1, tail: [2, 3])
    nums     // NonEmpty([1, 2, 3])

    // From Array — returns Optional (the array might be empty)
    let fromArr:   NonEmpty<Int>? = nonEmpty([1, 2, 3])
    let fromEmpty: NonEmpty<Int>? = nonEmpty([])
    fromArr as Any    // Optional(NonEmpty([1, 2, 3]))
    fromEmpty as Any  // nil
}
// learn(nonEmptyConstruction)

// MARK: - Properties

func nonEmptyProperties() {
    let ne = NonEmpty(head: 1, tail: [2, 3, 4, 5])

    ne.head     // 1 — always present, never Optional
    ne.tail     // [2, 3, 4, 5]
    ne.last     // 5
    ne.count    // 5
    ne.toArray  // [1, 2, 3, 4, 5]
}
// learn(nonEmptyProperties)

// MARK: - Functor

func nonEmptyFunctor() {
    let ne = NonEmpty(head: 1, tail: [2, 3])

    ne.map { $0 * 2 }      // NonEmpty([2, 4, 6])
    _ = { $0 * 2 } <£> ne  // NonEmpty([2, 4, 6]) — fn left
    ne <&> { $0 * 2 }      // NonEmpty([2, 4, 6]) — value left
    ne £> 0                // NonEmpty([0, 0, 0])
}
// learn(nonEmptyFunctor)

// MARK: - Monad

func nonEmptyMonad() {
    let ne = NonEmpty(head: 1, tail: [2, 3])

    // flatMap — expand each element, flatten into NonEmpty
    let expanded = ne.flatMap { n in NonEmpty(head: n, tail: [n * 10]) }
    expanded   // NonEmpty([1, 10, 2, 20, 3, 30])

    // bind (curried)
    let expand: (Int) -> NonEmpty<Int> = { n in NonEmpty(head: n, tail: [-n]) }
    NonEmpty<Int>.bind(expand)(ne)   // NonEmpty([1, -1, 2, -2, 3, -3])
    ne >>- expand                    // NonEmpty([1, -1, 2, -2, 3, -3])
}
// learn(nonEmptyMonad)

// MARK: - Semigroup (NOT Monoid)

func nonEmptySemigroup() {
    let a = NonEmpty(head: 1, tail: [2, 3])
    let b = NonEmpty(head: 4, tail: [5])
    let c = NonEmpty(head: 6, tail: [])

    // combine
    NonEmpty.combine(a, b)    // NonEmpty([1, 2, 3, 4, 5])
    a <> b                    // NonEmpty([1, 2, 3, 4, 5])

    // sconcat — fold via Semigroup (no identity needed)
    sconcat(a, [b, c])        // NonEmpty([1, 2, 3, 4, 5, 6])

    // mconcat is NOT available — there is no empty NonEmpty
}
// learn(nonEmptySemigroup)

// MARK: - Practical: type-safe non-empty input

func nonEmptyPractical() {
    func processItems(_ items: NonEmpty<String>) -> String {
        "Processing \(items.count) item(s), first: \(items.head)"
    }

    // Safe — only callable when we actually have items
    if let items = nonEmpty(["apple", "banana", "cherry"]) {
        processItems(items)   // "Processing 3 item(s), first: apple"
    }

    // head is always safe — no Optional, no force unwrap
    let fruits = NonEmpty(head: "apple", tail: ["banana"])
    fruits.head   // "apple"
}
// learn(nonEmptyPractical)

//: [Previous](@previous) | [Next](@next)
