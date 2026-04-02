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
    right.match(caseLeft: { "error: \($0)" }, caseRight: { "value: \($0)" })  // "value: 42"
    left.match (caseLeft: { "error: \($0)" }, caseRight: { "value: \($0)" })  // "error: not found"

    // SumType2 protocol
    right.b     // Optional(42)
    right.a     // nil
    right.isB   // true
    right.isA   // false
    left.a      // Optional("not found")
    left.b      // nil
    left.isA    // true
    left.isB    // false
}
// learnEitherConstruction()

// MARK: - Functor (Bifunctor)

func learnEitherFunctor() {
    let right: Either<String, Int> = .right(5)
    let left:  Either<String, Int> = .left("error")

    // fmap — maps the right side
    Either<String, Int>.fmap { $0 * 2 }(right)   // right(10)
    Either<String, Int>.fmap { $0 * 2 }(left)    // left("error")
    { $0 * 2 } <£> right                          // right(10)
    { $0 * 2 } <£> left                           // left("error")
    right <&> { $0 * 2 }                          // right(10)
    left <&> { $0 * 2 }                           // left("error")

    // mapLeft / mapRight — map one side
    right.mapRight { $0 * 2 }                     // right(10)
    left.mapRight { $0 * 2 }                      // left("error") — left unchanged
    left.mapLeft  { "[\($0)]" }                   // left("[error]")
    right.mapLeft { "[\($0)]" }                   // right(5) — right unchanged

    // bimap — map both sides independently
    right.bimap({ "[\($0)]" }, { $0 * 2 })        // right(10)
    left.bimap ({ "[\($0)]" }, { $0 * 2 })        // left("[error]")

    // replace
    right £> "done"                               // right("done")
    left £> "done"                                // left("error")
    "done" <£ right                               // right("done")
    "done" <£ left                                // left("error")
}
// learnEitherFunctor()

// MARK: - Applicative

func learnEitherApplicative() {
    let r1: Either<String, Int> = .right(3)
    let r2: Either<String, Int> = .right(4)
    let l1: Either<String, Int> = .left("fail")

    Either<String, Int>.liftA2(+)(r1, r2)           // right(7)
    Either<String, Int>.liftA2(+)(r1, l1)           // left("fail") — short-circuits

    let fn:    Either<String, (Int) -> Int> = .right { $0 + 10 }
    let errFn: Either<String, (Int) -> Int> = .left("no fn")
    fn <*> r1                                        // right(13)
    fn <*> l1                                        // left("fail")
    errFn <*> r1                                     // left("no fn")

    r1 *> r2                                         // right(4)
    l1 *> r2                                         // left("fail")
    r1 <* r2                                         // right(3)
    l1 <* r2                                         // left("fail")
}
// learnEitherApplicative()

// MARK: - Monad

func learnEitherMonad() {
    let right: Either<String, Int> = .right(5)
    let left:  Either<String, Int> = .left("error")

    // flatMap
    right.flatMap { n in n > 3 ? .right(n * 2) : .left("too small") }   // right(10)
    left.flatMap  { Either<String, Int>.right($0 * 2) }                  // left("error")

    // bind + operators
    let validate: (Int) -> Either<String, Int> = { $0 > 0 ? .right($0) : .left("non-positive") }
    right >>- validate                                                    // right(5)
    left >>- validate                                                     // left("error")
    validate -<< right                                                    // right(5)
    validate -<< left                                                     // left("error")

    // join
    Either<String, Int>.join(.right(.right(42)))     // right(42)
    Either<String, Int>.join(.right(.left("inner"))) // left("inner")
    Either<String, Int>.join(.left("outer"))         // left("outer")

    // Kleisli
    let parse:   (String) -> Either<String, Int> = { Int($0).map(Either.right) ?? .left("NaN") }
    let nonneg:  (Int) -> Either<String, Int>    = { $0 >= 0 ? .right($0) : .left("negative") }
    let check = parse >=> nonneg
    check("42")                                       // right(42)
    check("-1")                                       // left("negative")
    check("abc")                                      // left("NaN")
}
// learnEitherMonad()

// MARK: - Alternative

func learnEitherAlternative() {
    let r:  Either<String, Int> = .right(1)
    let l1: Either<String, Int> = .left("first")
    let l2: Either<String, Int> = .left("second")

    // Named function
    Either<String, Int>.alt(r, l1)    // right(1)  — first right wins
    Either<String, Int>.alt(l1, r)    // right(1)  — skip left, take right
    Either<String, Int>.alt(l1, l2)   // left("second") — last left

    // Operator
    r  <|> l1                         // right(1)
    l1 <|> r                          // right(1)
    l1 <|> l2                         // left("second") — last left
}
// learnEitherAlternative()

//: [Previous](@previous) | [Next](@next)
