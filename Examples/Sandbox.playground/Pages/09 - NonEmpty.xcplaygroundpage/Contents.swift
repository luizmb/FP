import FP

// ============================================================
// NONEMPTY<A>
//
// A sequence guaranteed to have at least one element.
// Semigroup but NOT Monoid — no empty value exists.
// Use sconcat (not mconcat) when folding a list of them.
// ============================================================

// MARK: - Construction

func learnNonEmptyConstruction() {
    // Direct init
    let digits = NonEmpty(head: 1, tail: [2, 3, 4])
    let single = NonEmpty(head: "only")

    print(digits)                                            // NonEmpty([1, 2, 3, 4])
    print(single)                                            // NonEmpty(["only"])

    // Free function constructors
    let nums = nonEmpty(head: 1, tail: [2, 3])
    print(nums)                                              // NonEmpty([1, 2, 3])

    // From Array — returns Optional (the array might be empty)
    let fromArr:   NonEmpty<Int>? = nonEmpty([1, 2, 3])
    let fromEmpty: NonEmpty<Int>? = nonEmpty([])
    print(fromArr as Any)                                    // Optional(NonEmpty([1, 2, 3]))
    print(fromEmpty as Any)                                  // nil
}
// learnNonEmptyConstruction()

// MARK: - Properties

func learnNonEmptyProperties() {
    let ne = NonEmpty(head: 1, tail: [2, 3, 4, 5])

    print(ne.head)                                           // 1 — always present, never Optional
    print(ne.tail)                                           // [2, 3, 4, 5]
    print(ne.last)                                           // 5
    print(ne.count)                                          // 5
    print(ne.toArray)                                        // [1, 2, 3, 4, 5]
}
// learnNonEmptyProperties()

// MARK: - Functor

func learnNonEmptyFunctor() {
    let ne = NonEmpty(head: 1, tail: [2, 3])

    print(ne.map { $0 * 2 })                                 // NonEmpty([2, 4, 6])
    print({ $0 * 2 } <£> ne)                                 // NonEmpty([2, 4, 6]) — fn left
    print(ne <&> { $0 * 2 })                                 // NonEmpty([2, 4, 6]) — value left
    print(ne £> 0)                                           // NonEmpty([0, 0, 0])
}
// learnNonEmptyFunctor()

// MARK: - Monad

func learnNonEmptyMonad() {
    let ne = NonEmpty(head: 1, tail: [2, 3])

    // flatMap — expand each element, flatten into NonEmpty
    let expanded = ne.flatMap { n in NonEmpty(head: n, tail: [n * 10]) }
    print(expanded)                                          // NonEmpty([1, 10, 2, 20, 3, 30])

    // bind (curried)
    let expand: (Int) -> NonEmpty<Int> = { n in NonEmpty(head: n, tail: [-n]) }
    print(NonEmpty<Int>.bind(expand)(ne))                    // NonEmpty([1, -1, 2, -2, 3, -3])
    print(ne >>- expand)                                     // NonEmpty([1, -1, 2, -2, 3, -3])
}
// learnNonEmptyMonad()

// MARK: - Semigroup (NOT Monoid)

func learnNonEmptySemigroup() {
    let a = NonEmpty(head: 1, tail: [2, 3])
    let b = NonEmpty(head: 4, tail: [5])
    let c = NonEmpty(head: 6, tail: [])

    // combine
    print(NonEmpty.combine(a, b))                            // NonEmpty([1, 2, 3, 4, 5])
    print(a <> b)                                            // NonEmpty([1, 2, 3, 4, 5])

    // sconcat — fold via Semigroup (no identity needed)
    print(sconcat(a, [b, c]))                                // NonEmpty([1, 2, 3, 4, 5, 6])

    // mconcat is NOT available — there is no empty NonEmpty
}
// learnNonEmptySemigroup()

// MARK: - Practical: type-safe non-empty input

func learnNonEmptyPractical() {
    func processItems(_ items: NonEmpty<String>) -> String {
        "Processing \(items.count) item(s), first: \(items.head)"
    }

    // Safe — only callable when we actually have items
    if let items = nonEmpty(["apple", "banana", "cherry"]) {
        print(processItems(items))                           // "Processing 3 item(s), first: apple"
    }

    // head is always safe — no Optional, no force unwrap
    let fruits = NonEmpty(head: "apple", tail: ["banana"])
    print(fruits.head)                                       // "apple"
}
// learnNonEmptyPractical()

//: [Previous](@previous) | [Next](@next)
