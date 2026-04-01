import FP

// ============================================================
// FOLDABLE  —  reduce a structure to a summary value
//
// foldLeft  :: b -> (b -> a -> b) -> f a -> b  (left-associative, strict)
// foldRight :: (a -> b -> b) -> b -> f a -> b  (right-associative)
// foldMap   :: Monoid m => (a -> m) -> f a -> m
// ============================================================

// MARK: - foldLeft

func learnFoldLeft() {
    let nums = [1, 2, 3, 4, 5]

    // Sum, product
    print(Array<Int>.foldLeft(0, +)(nums))                   // 15
    print(Array<Int>.foldLeft(1, *)(nums))                   // 120

    // Build a string left-to-right
    print(Array<Int>.foldLeft("") { acc, n in acc + "\(n)" }(nums))  // "12345"

    // Max without using max()
    print(Array<Int>.foldLeft(Int.min, { Swift.max($0, $1) })(nums))  // 5

    // Reverse a list
    print(Array<Int>.foldLeft([]) { acc, x in [x] + acc }(nums))      // [5,4,3,2,1]

    // Count elements matching a predicate
    print(Array<Int>.foldLeft(0) { acc, n in acc + (n % 2 == 0 ? 1 : 0) }(nums))  // 2
}
// learnFoldLeft()

// MARK: - foldRight

func learnFoldRight() {
    let nums = [1, 2, 3, 4, 5]

    // Sum (same as foldLeft for associative ops)
    print(Array<Int>.foldRight(+, 0)(nums))                  // 15

    // Build list in original order (prepend = correct order)
    print(Array<Int>.foldRight({ x, acc in [x] + acc }, [])(nums))   // [1,2,3,4,5]

    // Map via foldRight
    print(Array<Int>.foldRight({ x, acc in [x * 2] + acc }, [])(nums))  // [2,4,6,8,10]
}
// learnFoldRight()

// MARK: - foldMap

func learnFoldMap() {
    let nums = [1, 2, 3, 4, 5]
    let words = ["hello", "world", "!"]

    // Map to String (Monoid via concatenation), then combine
    print(Array<Int>.foldMap { "\($0)" }(nums))              // "12345"
    print(Array<String>.foldMap { $0.uppercased() }(words))  // "HELLOWORLD!"

    // Count positives: map to Int.Monoids.Sum (0 or 1), combine via +
    let mixed = [-1, 2, -3, 4, 5]
    print(Array<Int>.foldMap { n in Int.Monoids.Sum(n > 0 ? 1 : 0) }(mixed))
    // Sum(3)

    // Chain transformations using Endo as the Monoid
    let transforms: [(Int) -> Int] = [{ $0 + 1 }, { $0 * 2 }, { $0 - 3 }]
    let combined = Array.foldMap(Endo.init)(transforms)
    print(combined.runEndo(5))                               // ((5+1)*2)-3 = 9
}
// learnFoldMap()

// MARK: - Optional (also Foldable)

func learnFoldableOptional() {
    let x: Int?    = .some(5)
    let none: Int? = .none

    // withDefault — fold with a fallback
    print(x.withDefault(0))                                  // 5
    print(none.withDefault(0))                               // 0

    // Treat Optional as a list of 0 or 1 elements
    print(x.map { [$0] } ?? [])                              // [5]
    print(none.map { [$0] } ?? [])                           // []

    // foldMap-like: contribute to a Monoid if present
    print(x.map(String.init) ?? "")                         // "5"
    print(none.map(String.init) ?? "")                      // ""
}
// learnFoldableOptional()

//: [Previous](@previous) | [Next](@next)
