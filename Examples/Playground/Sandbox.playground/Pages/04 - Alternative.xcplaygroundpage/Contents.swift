import FP

// ============================================================
// ALTERNATIVE  —  alt :: f a -> f a -> f a  /  (<|>)
//
// Choose between two effects — return the first "success".
// Laws: left zero, right zero, associativity.
// ============================================================

// MARK: - Optional

func alternativeOptional() {
    let a: Int? = .some(1)
    let b: Int? = .some(2)
    let none: Int? = .none

    // Named function
    Optional<Int>.alt(a, b) // Optional(1) — first non-nil wins
    Optional<Int>.alt(none, b) // Optional(2) — fall through
    Optional<Int>.alt(none, none) // nil

    // Operator
    a <|> b // Optional(1)
    none <|> b // Optional(2)
    none <|> none // nil

    // Fallback chain
    let fromCache: Int? = nil
    let fromDB: Int? = nil
    let fallback: Int? = .some(0)
    fromCache <|> fromDB <|> fallback // Optional(0)
}

// learn(alternativeOptional)

// MARK: - Array

func alternativeArray() {
    let xs = [1, 2, 3]
    let ys = [4, 5]

    // For Array, alt = concatenation (both sides contribute)
    Array<Int>.alt(xs, ys) // [1, 2, 3, 4, 5]
    Array<Int>.alt([], ys) // [4, 5]

    xs <|> ys // [1, 2, 3, 4, 5]
    [] <|> ys // [4, 5]
    xs <|> [] // [1, 2, 3]
}

// learn(alternativeArray)

// MARK: - Either

func alternativeEither() {
    let r1: Either<String, Int> = .right(1)
    let l1: Either<String, Int> = .left("first error")
    let l2: Either<String, Int> = .left("second error")

    // Named function
    Either<String, Int>.alt(r1, l1) // right(1)  — first right wins
    Either<String, Int>.alt(l1, r1) // right(1)  — skip left, take right
    Either<String, Int>.alt(l1, l2) // left("second error") — last left

    // Operator
    r1 <|> l1 // right(1)
    l1 <|> r1 // right(1)
    l1 <|> l2 // left("second error")

    // Practical: try primary, fall back to secondary
    let primary: Either<String, Int> = .left("primary failed")
    let secondary: Either<String, Int> = .right(42)
    primary <|> secondary // right(42)
}

// learn(alternativeEither)

// MARK: - Result

func alternativeResult() {
    let ok1: Result<Int, AnyError> = .success(1)
    let fail1: Result<Int, AnyError> = .failure(AnyError("first"))
    let fail2: Result<Int, AnyError> = .failure(AnyError("second"))

    // Named function
    Result<Int, AnyError>.alt(ok1, fail1) // success(1) — first success wins
    Result<Int, AnyError>.alt(fail1, ok1) // success(1) — skip failure, take success
    Result<Int, AnyError>.alt(fail1, fail2) // failure(AnyError("second")) — last failure

    // Operator
    fail1 <|> ok1 // success(1)
    ok1 <|> fail1 // success(1)
    fail1 <|> fail2 // failure(AnyError("second"))
}

// learn(alternativeResult)

//: [Previous](@previous) | [Next](@next)
