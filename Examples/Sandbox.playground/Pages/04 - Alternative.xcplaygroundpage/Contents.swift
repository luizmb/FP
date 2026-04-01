import FP

// ============================================================
// ALTERNATIVE
// alt  :: f a -> f a -> f a    (or: choose first success)
// (<|>) operator
//
// Alternative models a choice between two effectful values.
// It returns the first one that "succeeds" — for Optional that
// means the first non-nil; for Array it means concatenation;
// for Either it means the first Right.
//
// Laws:
//   Left zero:      empty <|> x == x
//   Right zero:     x <|> empty == x
//   Associativity:  (x <|> y) <|> z == x <|> (y <|> z)
// ============================================================

// MARK: - Optional

// let a: Int? = .some(1)
// let b: Int? = .some(2)
// let none: Int? = .none

// --- Named function ---
// Optional<Int>.alt(a, b)                  // .some(1) — first non-nil wins
// Optional<Int>.alt(none, b)               // .some(2) — fall through to second
// Optional<Int>.alt(none, none)            // .none    — both nil

// --- Operator ---
// a <|> b                                  // .some(1)
// none <|> b                               // .some(2)
// none <|> none                            // .none

// --- Practical: fallback chain ---
// let fromCache: Int? = nil
// let fromDB: Int? = nil
// let defaultValue: Int? = .some(0)
// let result = fromCache <|> fromDB <|> defaultValue    // .some(0)


// MARK: - Array
// For Array, alt is concatenation — both sides contribute.

// let xs = [1, 2, 3]
// let ys = [4, 5]

// --- Named function ---
// [Int].alt(xs, ys)                        // [1, 2, 3, 4, 5]
// [Int].alt([], ys)                        // [4, 5]
// [Int].alt(xs, [])                        // [1, 2, 3]

// --- Operator ---
// xs <|> ys                                // [1, 2, 3, 4, 5]
// [] <|> ys                                // [4, 5]


// MARK: - Either
// For Either, alt returns the first Right, or the last Left.

// let r1: Either<String, Int> = .right(1)
// let r2: Either<String, Int> = .right(2)
// let l1: Either<String, Int> = .left("first error")
// let l2: Either<String, Int> = .left("second error")

// --- Named function ---
// Either<String, Int>.alt(r1, r2)          // .right(1) — first right wins
// Either<String, Int>.alt(l1, r1)          // .right(1) — skip left, take right
// Either<String, Int>.alt(r1, l1)          // .right(1) — already succeeded
// Either<String, Int>.alt(l1, l2)          // .left("second error") — last left

// --- Operator ---
// r1 <|> r2                                // .right(1)
// l1 <|> r1                                // .right(1)
// l1 <|> l2                                // .left("second error")

// --- Practical: try primary action, fallback to secondary ---
// let primary: Either<String, Int> = .left("primary failed")
// let fallback: Either<String, Int> = .right(42)
// primary <|> fallback                     // .right(42)


// MARK: - Result
// Mirrors Either: first Success, or last Failure.

// let ok1: Result<String, Int> = .success(1)
// let fail1: Result<String, Int> = .failure("first error")
// let fail2: Result<String, Int> = .failure("second error")

// --- Operator ---
// fail1 <|> ok1                            // .success(1)
// fail1 <|> fail2                          // .failure("second error")
// ok1 <|> fail1                            // .success(1)


// MARK: - Practical: parsing with fallback

// struct Parser<A> { let run: (String) -> A? }

// --- Try to parse an Int, fall back to parsing a Double, fall back to nil ---
// let intValue: Int? = Int("123")
// let doubleValue: Int? = Double("3.14").map(Int.init)
// let value = intValue <|> doubleValue     // .some(123)

// let intFromBad: Int? = Int("3.14")       // nil
// let fallback = intFromBad <|> doubleValue  // .some(3)

//: [Previous](@previous) | [Next](@next)
