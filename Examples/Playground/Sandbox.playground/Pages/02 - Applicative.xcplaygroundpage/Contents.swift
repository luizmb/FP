import FP

// ============================================================
// APPLICATIVE  —  liftA2 :: (a -> b -> c) -> f a -> f b -> f c
//
// Combine independent effects. Unlike Monad, neither value
// depends on the other — they can be evaluated in any order.
// Laws: identity, composition, homomorphism, interchange.
// ============================================================

// MARK: - Optional

func learnApplicativeOptional() {
    let x: Int? = 3
    let y: Int? = 4
    let none: Int? = nil

    // liftA2 — combine two independents with a binary fn
    Optional<Int>.liftA2(+)(x, y)       // Optional(7)
    Optional<Int>.liftA2(+)(x, none)    // nil — any nil propagates

    // apply — wrapped function applied to wrapped value
    let fn:   ((Int) -> Int)? = .some { $0 * 2 }
    let noFn: ((Int) -> Int)? = .none
    Optional.apply(fn, x)               // Optional(6)
    Optional.apply(noFn, x)             // nil — nil fn propagates
    fn <*> x                            // Optional(6) — operator
    fn <*> none                         // nil
    noFn <*> x                          // nil

    // seqRight / seqLeft — run both, discard one side
    x.seqRight(y)                        // Optional(4)
    none.seqRight(y)                     // nil
    x *> y                              // Optional(4) — operator
    none *> y                           // nil
    x.seqLeft(y)                         // Optional(3)
    x.seqLeft(none)                      // nil
    x <* y                              // Optional(3) — operator
    x <* none                           // nil — none propagates

    // zip
    Optional<(Int, Int)>.zip(x, y)      // Optional((3, 4))
    Optional<(Int, Int)>.zip(x, none)   // nil
}
// learnApplicativeOptional()

// MARK: - Array

func learnApplicativeArray() {
    let xs = [1, 2, 3]
    let ys = [10, 20]

    // liftA2 — cartesian product mapped through a binary fn
    Array<Int>.liftA2(+)(xs, ys)    // [11, 21, 12, 22, 13, 23]

    // apply — each fn applied to each value
    let fns: [(Int) -> Int] = [{ $0 + 1 }, { $0 * 2 }]
    fns <*> xs                       // [2, 3, 4, 2, 4, 6]

    // seqRight / seqLeft
    xs *> ys                         // [10, 20, 10, 20, 10, 20]
    xs <* ys                         // [1, 1, 2, 2, 3, 3]
}
// learnApplicativeArray()

// MARK: - Result

func learnApplicativeResult() {
    let ok1: Result<Int, AnyError> = .success(3)
    let ok2: Result<Int, AnyError> = .success(4)
    let err: Result<Int, AnyError> = .failure(AnyError("oops"))

    Result<Int, AnyError>.liftA2(+)(ok1, ok2)   // success(7)
    Result<Int, AnyError>.liftA2(+)(ok1, err)   // failure(AnyError("oops")) — short-circuits

    let fn:    Result<(Int) -> Int, AnyError> = .success { $0 * 2 }
    let errFn: Result<(Int) -> Int, AnyError> = .failure(AnyError("no fn"))
    fn <*> ok1                                   // success(6)
    fn <*> err                                   // failure(AnyError("oops"))
    errFn <*> ok1                                // failure(AnyError("no fn"))

    ok1 *> ok2                                   // success(4)
    ok1 *> err                                   // failure(AnyError("oops"))
    ok1 <* ok2                                   // success(3)
    ok1 <* err                                   // failure(AnyError("oops"))
}
// learnApplicativeResult()

// MARK: - Either

func learnApplicativeEither() {
    let r1: Either<String, Int> = .right(3)
    let r2: Either<String, Int> = .right(4)
    let l1: Either<String, Int> = .left("fail")

    Either<String, Int>.liftA2(+)(r1, r2)    // right(7)
    Either<String, Int>.liftA2(+)(r1, l1)    // left("fail") — short-circuits

    let fn:    Either<String, (Int) -> Int> = .right { $0 + 10 }
    let errFn: Either<String, (Int) -> Int> = .left("no fn")
    fn <*> r1                                 // right(13)
    fn <*> l1                                 // left("fail")
    errFn <*> r1                              // left("no fn")

    r1 *> r2                                  // right(4)
    l1 *> r2                                  // left("fail")
    r1 <* r2                                  // right(3)
    l1 <* r2                                  // left("fail")
}
// learnApplicativeEither()

// MARK: - Validation (accumulates ALL errors — the key difference)

func learnApplicativeValidation() {
    let ok1: Validation<[String], Int>  = .success(3)
    let ok2: Validation<[String], Int>  = .success(4)
    let e1:  Validation<[String], Int>  = .failure(["name is empty"])
    let e2:  Validation<[String], Int>  = .failure(["age is negative"])

    // liftA2 — collects ALL errors, not just the first
    Validation<[String], Int>.liftA2(+)(ok1, ok2)   // success(7)
    Validation<[String], Int>.liftA2(+)(e1, ok2)    // failure(["name is empty"])
    Validation<[String], Int>.liftA2(+)(e1, e2)
    // failure(["name is empty", "age is negative"]) ← BOTH errors!

    // Compare: Either short-circuits on first error
    let l1: Either<[String], Int> = .left(["name is empty"])
    let l2: Either<[String], Int> = .left(["age is negative"])
    Either<[String], Int>.liftA2(+)(l1, l2)
    // left(["name is empty"]) ← only first!

    // zip — accumulate errors across fields
    Validation<[String], (Int, Int)>.zip(ok1, ok2)   // success((3, 4))
    Validation<[String], (Int, Int)>.zip(e1, e2)     // failure(["name is empty", "age is negative"])

    // zip3 — three fields
    let e3: Validation<[String], String> = .failure(["email invalid"])
    Validation<[String], (Int, Int, String)>.zip3(e1, e2, e3)
    // failure(["name is empty", "age is negative", "email invalid"])
}
// learnApplicativeValidation()

// MARK: - Reader

struct ApplicativeReaderEnv { let x: Int; let y: Int }

func learnApplicativeReader() {
    let rx = Reader<ApplicativeReaderEnv, Int>.asks(\.x)
    let ry = Reader<ApplicativeReaderEnv, Int>.asks(\.y)

    // liftA2 — both readers share the same env, results combined
    let sum = Reader<ApplicativeReaderEnv, Int>.liftA2(+)(rx, ry)
    sum.runReader(ApplicativeReaderEnv(x: 3, y: 4))    // 7

    // seqRight — run both, keep second
    let keepY = rx *> ry
    keepY.runReader(ApplicativeReaderEnv(x: 3, y: 4))  // 4
}
// learnApplicativeReader()

//: [Previous](@previous) | [Next](@next)
