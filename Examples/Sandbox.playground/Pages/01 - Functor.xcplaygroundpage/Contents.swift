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
    print(Optional<Int>.fmap { $0 * 2 }(x))        // Optional(10)
    print(Optional<Int>.fmap { $0 * 2 }(none))     // nil

    // Instance method
    print(x.map { $0 * 2 })                         // Optional(10)

    // Operators
    print({ $0 * 2 } <£> x)                         // Optional(10) — fn left
    print(x <&> { $0 * 2 })                         // Optional(10) — value left
    print(x £> "hello")                             // Optional("hello") — replace
    print("hello" <£ x)                             // Optional("hello") — flipped
}
// learnFunctorOptional()

// MARK: - Array

func learnFunctorArray() {
    let arr = [1, 2, 3]

    // Named function (curried static)
    print(Array<Int>.fmap { $0 * 2 }(arr))          // [2, 4, 6]

    // Instance method
    print(arr.map { $0 * 2 })                        // [2, 4, 6]

    // Operators
    print({ $0 * 2 } <£> arr)                        // [2, 4, 6] — fn left
    print(arr <&> { $0 * 2 })                        // [2, 4, 6] — value left
    print(arr £> 0)                                   // [0, 0, 0] — replace each
}
// learnFunctorArray()

// MARK: - Result

func learnFunctorResult() {
    let ok:  Result<String, Int> = .success(5)
    let err: Result<String, Int> = .failure("oops")

    print(Result<String, Int>.fmap { $0 * 2 }(ok))  // success(10)
    print(Result<String, Int>.fmap { $0 * 2 }(err)) // failure("oops")
    print({ $0 * 2 } <£> ok)                         // success(10)
    print(ok <&> { $0 * 2 })                         // success(10)

    // Bifunctor — map each side independently
    print(ok.mapRight { $0 * 2 })                    // success(10)
    print(err.mapLeft { "[\($0)]" })                 // failure("[oops]")
    print(ok.bimap({ "[\($0)]" }, { $0 * 2 }))      // success(10)
}
// learnFunctorResult()

// MARK: - Either

func learnFunctorEither() {
    let right: Either<String, Int> = .right(5)
    let left:  Either<String, Int> = .left("error")

    print(Either<String, Int>.fmap { $0 * 2 }(right)) // right(10)
    print(Either<String, Int>.fmap { $0 * 2 }(left))  // left("error")
    print({ $0 * 2 } <£> right)                        // right(10)
    print(right <&> { $0 * 2 })                        // right(10)

    // Bifunctor
    print(right.mapRight { $0 * 2 })                   // right(10)
    print(left.mapLeft { "[\($0)]" })                  // left("[error]")
    print(right.bimap({ "[\($0)]" }, { $0 * 2 }))     // right(10)
    print(left.bimap ({ "[\($0)]" }, { $0 * 2 }))     // left("[error]")
}
// learnFunctorEither()

// MARK: - Reader

struct FunctorReaderEnv { let factor: Int }

func learnFunctorReader() {
    let r = Reader<FunctorReaderEnv, Int> { $0.factor }

    let doubled = r.mapReader { $0 * 2 }
    print(doubled.runReader(FunctorReaderEnv(factor: 3)))   // 6

    let shifted = { $0 + 10 } <£> r
    print(shifted.runReader(FunctorReaderEnv(factor: 3)))   // 13
}
// learnFunctorReader()

// MARK: - Writer

func learnFunctorWriter() {
    let w = Writer(5, ["got 5"])

    let doubled  = w.fmap { $0 * 2 }
    print(doubled.runWriter())                       // (10, ["got 5"])

    let withOp   = { $0 * 2 } <£> w
    print(withOp.runWriter())                        // (10, ["got 5"])

    let replaced = w £> "done"
    print(replaced.runWriter())                      // ("done", ["got 5"])
}
// learnFunctorWriter()

// MARK: - Stateful

func learnFunctorStateful() {
    let s = Stateful<Int, Int> { state in state * 2 }

    let asString = s.fmap { "value: \($0)" }
    print(asString.eval(5))                          // "value: 10"

    let withOp = { "v: \($0)" } <£> s
    print(withOp.eval(3))                            // "v: 6"
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
        print(await doubled.run())                   // 10
        print(await withOp1.run())                   // 10
        print(await withOp2.run())                   // 10
        print(await replaced.run())                  // "done"
    }
}
// learnFunctorDeferredTask()

//: [Next](@next)
