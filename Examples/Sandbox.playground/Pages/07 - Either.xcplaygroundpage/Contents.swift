import FP

// ============================================================
// EITHER<A, B>
//
// Unconstrained sum type: .left(A) | .right(B).
// Unlike Result, neither side is constrained to Error.
// .right is the "success" side by convention.
// Conforms to SumType2: .a (left), .b (right), .isA, .isB.
// ============================================================

// MARK: - Construction & Pattern Matching

func learnEitherConstruction() {
    let right: Either<String, Int> = .right(42)
    let left:  Either<String, Int> = .left("not found")

    // match — exhaustive pattern match (both cases required)
    print(right.match(caseLeft: { "error: \($0)" }, caseRight: { "value: \($0)" }))  // "value: 42"
    print(left.match (caseLeft: { "error: \($0)" }, caseRight: { "value: \($0)" }))  // "error: not found"

    // SumType2 protocol
    print(right.b)                                           // Optional(42)
    print(right.a)                                           // nil
    print(right.isB)                                         // true
    print(left.a)                                            // Optional("not found")
    print(left.isA)                                          // true
}
// learnEitherConstruction()

// MARK: - Functor (Bifunctor)

func learnEitherFunctor() {
    let right: Either<String, Int> = .right(5)
    let left:  Either<String, Int> = .left("error")

    // fmap — maps the right side
    print(Either<String, Int>.fmap { $0 * 2 }(right))       // right(10)
    print(Either<String, Int>.fmap { $0 * 2 }(left))        // left("error")
    print({ $0 * 2 } <£> right)                             // right(10)
    print(right <&> { $0 * 2 })                             // right(10)

    // mapLeft / mapRight — map one side
    print(right.mapRight { $0 * 2 })                        // right(10)
    print(left.mapLeft  { "[\($0)]" })                      // left("[error]")
    print(right.mapLeft { "[\($0)]" })                      // right(5) — right unchanged

    // bimap — map both sides independently
    print(right.bimap({ "[\($0)]" }, { $0 * 2 }))          // right(10)
    print(left.bimap ({ "[\($0)]" }, { $0 * 2 }))          // left("[error]")

    // replace
    print(right £> "done")                                   // right("done")
    print("done" <£ right)                                   // right("done")
}
// learnEitherFunctor()

// MARK: - Applicative

func learnEitherApplicative() {
    let r1: Either<String, Int> = .right(3)
    let r2: Either<String, Int> = .right(4)
    let l1: Either<String, Int> = .left("fail")

    print(Either<String, Int>.liftA2(+)(r1, r2))            // right(7)
    print(Either<String, Int>.liftA2(+)(r1, l1))            // left("fail") — short-circuits

    let fn: Either<String, (Int) -> Int> = .right { $0 + 10 }
    print(fn <*> r1)                                         // right(13)
    print(fn <*> l1)                                         // left("fail")

    print(r1 *> r2)                                          // right(4)
    print(r1 <* r2)                                          // right(3)
}
// learnEitherApplicative()

// MARK: - Monad

func learnEitherMonad() {
    let right: Either<String, Int> = .right(5)
    let left:  Either<String, Int> = .left("error")

    // flatMap
    print(right.flatMap { n in n > 3 ? .right(n * 2) : .left("too small") })  // right(10)
    print(left.flatMap  { Either<String, Int>.right($0 * 2) })                 // left("error")

    // bind + operators
    let validate: (Int) -> Either<String, Int> = { $0 > 0 ? .right($0) : .left("non-positive") }
    print(right >>- validate)                                // right(5)
    print(validate -<< right)                               // right(5)

    // join
    print(Either<String, Int>.join(.right(.right(42))))     // right(42)
    print(Either<String, Int>.join(.right(.left("inner")))) // left("inner")

    // Kleisli
    let parse:   (String) -> Either<String, Int> = { Int($0).map(Either.right) ?? .left("NaN") }
    let nonneg:  (Int) -> Either<String, Int>    = { $0 >= 0 ? .right($0) : .left("negative") }
    let check = parse >=> nonneg
    print(check("42"))                                       // right(42)
    print(check("-1"))                                       // left("negative")
    print(check("abc"))                                      // left("NaN")
}
// learnEitherMonad()

// MARK: - Alternative

func learnEitherAlternative() {
    let r:  Either<String, Int> = .right(1)
    let l1: Either<String, Int> = .left("first")
    let l2: Either<String, Int> = .left("second")

    print(r  <|> l1)                                        // right(1)
    print(l1 <|> r)                                         // right(1)
    print(l1 <|> l2)                                        // left("second") — last left
}
// learnEitherAlternative()

//: [Previous](@previous) | [Next](@next)
