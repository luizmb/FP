import FP

// ============================================================
// EITHER<A, B>
//
// Either is an unconstrained sum type: .left(A) or .right(B).
// Unlike Result, neither side is constrained — both A and B can
// be any type. By convention, .right is the "success" side and
// .left is the "error" side, but nothing enforces this.
//
// Compared to Result<Success, Failure>:
//   - Result requires Failure: Error; Either has no constraints
//   - Either can encode non-error disjunctions (left/right choice)
//   - Both are Functor/Applicative/Monad on the right side
//
// SumType2 protocol gives .a (left), .b (right), .isA, .isB, .match
// ============================================================

// MARK: - Construction & Pattern Matching

// let right: Either<String, Int> = .right(42)
// let left:  Either<String, Int> = .left("not found")

// --- match: total pattern matching (both cases required) ---
// right.match(caseLeft: { "error: \($0)" }, caseRight: { "value: \($0)" })   // "value: 42"
// left.match(caseLeft:  { "error: \($0)" }, caseRight: { "value: \($0)" })   // "error: not found"

// --- SumType2 protocol ---
// right.b                                  // Optional(42)   — right side (the "b")
// right.a                                  // nil            — left side (the "a")
// right.isB                                // true
// right.isA                                // false
// left.a                                   // Optional("not found")


// MARK: - Functor (map right side)

// let right: Either<String, Int> = .right(5)

// --- mapRight (alias: fmap) ---
// right.mapRight { $0 * 2 }                // .right(10)
// Either<String, Int>.fmap { $0 * 2 }(right)  // .right(10)
// { $0 * 2 } <£> right                    // .right(10)
// right <&> { $0 * 2 }                    // .right(10)

// --- mapLeft ---
// let left: Either<String, Int> = .left("error")
// left.mapLeft { "[\($0)]" }               // .left("[error]")
// right.mapLeft { "[\($0)]" }              // .right(5) — right untouched

// --- bimap: map both sides independently ---
// right.bimap({ "[\($0)]" }, { $0 * 2 })  // .right(10)
// left.bimap({ "[\($0)]" }, { $0 * 2 })   // .left("[error]")

// --- replace ---
// right £> "done"                          // .right("done")
// "done" <£ right                          // .right("done")


// MARK: - Applicative

// let r1: Either<String, Int> = .right(3)
// let r2: Either<String, Int> = .right(4)
// let l1: Either<String, Int> = .left("first error")

// --- liftA2: combine two rights ---
// Either<String, Int>.liftA2(+)(r1, r2)   // .right(7)
// Either<String, Int>.liftA2(+)(r1, l1)   // .left("first error") — short-circuits

// --- apply ---
// let fn: Either<String, (Int) -> Int> = .right { $0 + 10 }
// fn <*> r1                                // .right(13)

// --- seqRight / seqLeft ---
// r1 *> r2                                 // .right(4)
// r1 <* r2                                 // .right(3)
// r1 *> l1                                 // .left("first error")


// MARK: - Monad

// let right: Either<String, Int> = .right(5)
// let left:  Either<String, Int> = .left("error")

// --- flatMap (instance) ---
// right.flatMap { n in n > 3 ? .right(n * 2) : .left("too small") }  // .right(10)
// right.flatMap { _ in Either<String, Int>.left("step failed") }       // .left("step failed")
// left.flatMap  { n in .right(n * 2) }     // .left("error") — left propagates

// --- bind (curried) ---
// let safeDivide: (Int) -> Either<String, Int> = { $0 == 0 ? .left("division by zero") : .right(100 / $0) }
// right >>- safeDivide                    // .right(20)
// left  >>- safeDivide                    // .left("error")
// safeDivide -<< right                    // .right(20)

// --- join: flatten nested Either ---
// let nested: Either<String, Either<String, Int>> = .right(.right(42))
// Either<String, Int>.join(nested)         // .right(42)

// --- Kleisli composition ---
// let parse: (String) -> Either<String, Int> = { Int($0).map(Either.right) ?? .left("not a number") }
// let nonneg: (Int) -> Either<String, Int>   = { $0 >= 0 ? .right($0) : .left("negative") }
// let composed = parse >=> nonneg
// composed("42")                           // .right(42)
// composed("-1")                           // .left("negative")
// composed("abc")                          // .left("not a number")


// MARK: - Alternative (first .right wins)

// let r: Either<String, Int> = .right(1)
// let l1: Either<String, Int> = .left("first error")
// let l2: Either<String, Int> = .left("second error")

// Either<String, Int>.alt(r, l1)           // .right(1)
// Either<String, Int>.alt(l1, r)           // .right(1)
// Either<String, Int>.alt(l1, l2)          // .left("second error")
// r <|> l1                                 // .right(1)
// l1 <|> l2                                // .left("second error")


// MARK: - Either vs Result interop

// let result: Result<Error, Int> = .success(42)
// // Convert Either -> Result:
// let asResult: Result<String, Int> = right.match(caseLeft: Result.failure, caseRight: Result.success)
// // Convert Result -> Either:
// let ok: Result<String, Int> = .success(10)
// let asEither: Either<String, Int> = ok.map(Either<String, Int>.right).mapError(Either<String, Int>.left) |> { _ in fatalError() }
// // More idiomatically via match on the right side:
// let fromResult: Either<String, Int> = .right(10)

//: [Previous](@previous) | [Next](@next)
