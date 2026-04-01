import FP

// ============================================================
// ALTERNATIVE  —  alt :: f a -> f a -> f a  /  (<|>)
//
// Choose between two effects — return the first "success".
// Laws: left zero, right zero, associativity.
// ============================================================

// MARK: - Optional

func learnAlternativeOptional() {
    let a: Int?    = .some(1)
    let b: Int?    = .some(2)
    let none: Int? = .none

    // Named function
    print(Optional<Int>.alt(a, b))                  // Optional(1) — first non-nil wins
    print(Optional<Int>.alt(none, b))               // Optional(2) — fall through
    print(Optional<Int>.alt(none, none))            // nil

    // Operator
    print(a <|> b)                                  // Optional(1)
    print(none <|> b)                               // Optional(2)
    print(none <|> none)                            // nil

    // Fallback chain
    let fromCache: Int? = nil
    let fromDB:    Int? = nil
    let fallback:  Int? = .some(0)
    print(fromCache <|> fromDB <|> fallback)        // Optional(0)
}
// learnAlternativeOptional()

// MARK: - Array

func learnAlternativeArray() {
    let xs = [1, 2, 3]
    let ys = [4, 5]

    // For Array, alt = concatenation (both sides contribute)
    print(Array<Int>.alt(xs, ys))                   // [1, 2, 3, 4, 5]
    print(Array<Int>.alt([], ys))                   // [4, 5]

    print(xs <|> ys)                                // [1, 2, 3, 4, 5]
    print([] <|> ys)                                // [4, 5]
    print(xs <|> [])                                // [1, 2, 3]
}
// learnAlternativeArray()

// MARK: - Either

func learnAlternativeEither() {
    let r1: Either<String, Int> = .right(1)
    let l1: Either<String, Int> = .left("first error")
    let l2: Either<String, Int> = .left("second error")

    // Named function
    print(Either<String, Int>.alt(r1, l1))          // right(1)  — first right wins
    print(Either<String, Int>.alt(l1, r1))          // right(1)  — skip left, take right
    print(Either<String, Int>.alt(l1, l2))          // left("second error") — last left

    // Operator
    print(r1 <|> l1)                                // right(1)
    print(l1 <|> r1)                                // right(1)
    print(l1 <|> l2)                                // left("second error")

    // Practical: try primary, fall back to secondary
    let primary:  Either<String, Int> = .left("primary failed")
    let secondary: Either<String, Int> = .right(42)
    print(primary <|> secondary)                    // right(42)
}
// learnAlternativeEither()

// MARK: - Result

func learnAlternativeResult() {
    let ok1: Result<String, Int>  = .success(1)
    let fail1: Result<String, Int> = .failure("first")
    let fail2: Result<String, Int> = .failure("second")

    print(fail1 <|> ok1)                            // success(1)
    print(ok1   <|> fail1)                          // success(1)
    print(fail1 <|> fail2)                          // failure("second")
}
// learnAlternativeResult()

//: [Previous](@previous) | [Next](@next)
