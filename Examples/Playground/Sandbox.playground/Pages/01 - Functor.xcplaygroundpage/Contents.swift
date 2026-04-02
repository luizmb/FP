import FP

// ============================================================
// FUNCTOR  —  fmap :: (a -> b) -> f a -> f b
//
// Map a pure function over a wrapped value without changing
// the structure. Laws: identity, composition.
// ============================================================

// MARK: - Optional

func learnFunctorOptional() {
    let x: Int? = 5
    let none: Int? = nil

    // Named function (curried static)
    Optional<Int>.fmap { $0 * 2 }(x)        // Optional(10)
    Optional<Int>.fmap { $0 * 2 }(none)     // nil

    // Instance method
    x.map { $0 * 2 }                         // Optional(10)
    none.map { $0 * 2 }                      // nil

    // Operators
    _ = { $0 * 2 } <£> x                     // Optional(10) — fn left
    _ = { $0 * 2 } <£> none                  // nil
    x <&> { $0 * 2 }                         // Optional(10) — value left
    none <&> { $0 * 2 }                      // nil
    x £> "hello"                             // Optional("hello") — replace
    none £> "hello"                          // nil
    "hello" <£ x                             // Optional("hello") — flipped
    "hello" <£ none                          // nil
}
learnFunctorOptional()

// MARK: - Array
func learnFunctorArray() {
    let arr = [1, 2, 3]

    // Named function (curried static)
    Array<Int>.fmap { $0 * 2 }(arr)    // [2, 4, 6]

    // Instance method
    arr.map { $0 * 2 }                  // [2, 4, 6]

    // Operators
    { $0 * 2 } <£> arr                  // [2, 4, 6] — fn left
    arr <&> { $0 * 2 }                  // [2, 4, 6] — value left
    arr £> 0                            // [0, 0, 0] — replace each
}
// learnFunctorArray()

// MARK: - Result

func learnFunctorResult() {
    let ok:  Result<Int, AnyError> = .success(5)
    let err: Result<Int, AnyError> = .failure(AnyError("oops"))

    Result<Int, AnyError>.fmap { $0 * 2 }(ok)   // success(10)
    Result<Int, AnyError>.fmap { $0 * 2 }(err)  // failure(AnyError("oops"))

    _ = { $0 * 2 } <£> ok                       // success(10)
    _ = { $0 * 2 } <£> err                      // failure(AnyError("oops"))
    ok <&> { $0 * 2 }                           // success(10)
    err <&> { $0 * 2 }                          // failure(AnyError("oops"))

    // Bifunctor — map each side independently
    ok.mapLeft { $0 * 2 }                                       // success(10) — maps Success
    err.mapLeft { $0 * 2 }                                      // failure(AnyError("oops")) — failure unchanged
    err.mapRight { AnyError("[\($0.message)]") }                // failure(AnyError("[oops]")) — maps Failure
    ok.mapRight { AnyError("[\($0.message)]") }                 // success(5) — success unchanged
    ok.bimap({ $0 * 2 }, { AnyError("[\($0.message)]") })      // success(10)
    err.bimap({ $0 * 2 }, { AnyError("[\($0.message)]") })     // failure(AnyError("[oops]"))
}
// learnFunctorResult()

// MARK: - Either

func learnFunctorEither() {
    let right: Either<String, Int> = .right(5)
    let left:  Either<String, Int> = .left("error")

    Either<String, Int>.fmap { $0 * 2 }(right)  // right(10)
    Either<String, Int>.fmap { $0 * 2 }(left)   // left("error")
    _ = { $0 * 2 } <£> right                    // right(10)
    _ = { $0 * 2 } <£> left                     // left("error")
    right <&> { $0 * 2 }                        // right(10)
    left <&> { $0 * 2 }                         // left("error")

    // Bifunctor
    right.mapRight { $0 * 2 }                   // right(10)
    left.mapRight { $0 * 2 }                    // left("error") — left unchanged
    left.mapLeft { "[\($0)]" }                  // left("[error]")
    right.mapLeft { "[\($0)]" }                 // right(5) — right unchanged
    right.bimap({ "[\($0)]" }, { $0 * 2 })      // right(10)
    left.bimap ({ "[\($0)]" }, { $0 * 2 })      // left("[error]")
}
// learnFunctorEither()

// MARK: - Reader

struct FunctorReaderEnv { let factor: Int }

func learnFunctorReader() {
    let r = Reader<FunctorReaderEnv, Int> { $0.factor }

    let doubled = r.mapReader { $0 * 2 }
    doubled.runReader(FunctorReaderEnv(factor: 3))   // 6

    let shifted = { $0 + 10 } <£> r
    shifted.runReader(FunctorReaderEnv(factor: 3))   // 13
}
// learnFunctorReader()

// MARK: - Writer

func learnFunctorWriter() {
    let w = Writer(5, ["got 5"])

    let doubled  = w.fmap { $0 * 2 }
    let withOp   = { $0 * 2 } <£> w
    let replaced = w £> "done"

    doubled.runWriter()    // (10, ["got 5"])
    withOp.runWriter()     // (10, ["got 5"])
    replaced.runWriter()   // ("done", ["got 5"])
}
// learnFunctorWriter()

// MARK: - Stateful

func learnFunctorStateful() {
    let s = Stateful<Int, Int> { state in state * 2 }

    let asString = s.fmap { "value: \($0)" }
    asString.eval(5)                // "value: 10"

    let withOp = { "v: \($0)" } <£> s
    withOp.eval(3)                  // "v: 6"
}
// learnFunctorStateful()

// MARK: - DeferredTask

func learnFunctorDeferredTask() {
    let task     = DeferredTask { 5 }
    let doubled  = task.fmap { $0 * 2 }             // still lazy
    let withOp1  = { $0 * 2 } <£> task
    let withOp2  = task <&> { $0 * 2 }
    let replaced = task £> "done"

    Task {
        await doubled.run()    // 10
        await withOp1.run()    // 10
        await withOp2.run()    // 10
        await replaced.run()   // "done"
    }
}
// learnFunctorDeferredTask()

//: [Next](@next)

