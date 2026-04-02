import FP
import Combine

// ============================================================
// MONAD  —  bind :: m a -> (a -> m b) -> m b
//
// Sequence effects where each step can depend on the previous
// result. Kleisli composition (>=>) is function composition
// in the Kleisli category — derived from bind, just as (.)
// is derived from ($).
// Laws: left identity, right identity, associativity.
// ============================================================

// MARK: - Optional

func monadOptional() {
    let x:    Int? = 5
    let none: Int? = nil

    // flatMap (instance)
    x.flatMap { $0 > 3 ? .some($0 * 2) : .none }    // Optional(10)
    x.flatMap { _ in Int?.none }                      // nil
    none.flatMap { .some($0 * 2) }                   // nil

    // bind (curried static)
    let positive: (Int) -> Int? = { $0 > 0 ? .some($0) : .none }
    Optional<Int>.bind(positive)(x)                   // Optional(5)
    Optional<Int>.bind(positive)(nil)                 // nil

    // Operators
    x >>- positive                                    // Optional(5) — value left
    none >>- positive                                 // nil
    positive -<< x                                    // Optional(5) — fn left
    positive -<< none                                 // nil

    // join — flatten nested Optional
    Optional<Int>.join(.some(.some(42)))              // Optional(42)
    Optional<Int>.join(.some(Optional<Int>.none))     // nil

    // Kleisli — compose two (a -> m b) arrows
    let parseInt: (String) -> Int? = { Int($0) }
    let nonneg:   (Int) -> Int?    = { $0 >= 0 ? .some($0) : .none }
    let composed  = parseInt >=> nonneg
    composed("5")                                     // Optional(5)
    composed("-1")                                    // nil
    composed("abc")                                   // nil

    let reversed  = nonneg <=< parseInt               // right-to-left, same result
    reversed("5")                                     // Optional(5)
}
// learn(monadOptional)

// MARK: - Array

func monadArray() {
    // flatMap — expand each element, flatten
    [1, 2, 3].flatMap { [$0, $0 * 10] }              // [1, 10, 2, 20, 3, 30]

    // bind (curried)
    let expand: (Int) -> [Int] = { [$0, -$0] }
    Array<Int>.bind(expand)([1, 2, 3])               // [1, -1, 2, -2, 3, -3]

    // Operators
    [1, 2, 3] >>- expand                             // [1, -1, 2, -2, 3, -3] — value left
    expand -<< [1, 2, 3]                             // [1, -1, 2, -2, 3, -3] — fn left

    // join — flatten nested array
    Array<Int>.join([[1, 2], [3], [4, 5]])           // [1, 2, 3, 4, 5]

    // Kleisli
    let digits:  (Int) -> [Int] = { n in n < 10 ? [n] : [n / 10, n % 10] }
    let doubled: (Int) -> [Int] = { [$0, $0 * 2] }
    let split  = digits >=> doubled
    split(12)                                         // [1, 2, 2, 4]

    let splitR = doubled <=< digits                   // right-to-left, same result
    splitR(12)                                        // [1, 2, 2, 4]
}
// learn(monadArray)

// MARK: - Result

func monadResult() {
    let ok:  Result<Int, AnyError> = .success(5)
    let err: Result<Int, AnyError> = .failure(AnyError("bad"))

    ok.flatMap { $0 > 3 ? .success($0 * 2) : .failure(AnyError("too small")) }   // success(10)
    err.flatMap { .success($0 * 2) }                                               // failure("bad")

    // Operators
    ok >>- { _ in Result<Int, AnyError>.failure(AnyError("step failed")) }        // failure("step failed")
    err >>- { .success($0 * 2) }                                                   // failure("bad")
    _ = { _ in Result<Int, AnyError>.failure(AnyError("step failed")) } -<< ok    // failure("step failed")

    // join — flatten nested Result (typed vars needed for inference)
    let nestedOk:   Result<Result<Int, AnyError>, AnyError> = .success(.success(42))
    let nestedFail: Result<Result<Int, AnyError>, AnyError> = .success(.failure(AnyError("inner")))
    let outerFail:  Result<Result<Int, AnyError>, AnyError> = .failure(AnyError("outer"))
    Result<Result<Int, AnyError>, AnyError>.join(nestedOk)    // success(42)
    Result<Result<Int, AnyError>, AnyError>.join(nestedFail)  // failure("inner")
    Result<Result<Int, AnyError>, AnyError>.join(outerFail)   // failure("outer")

    // Kleisli
    let parse:    (String) -> Result<Int, AnyError> = { Int($0).map(Result.success) ?? .failure(AnyError("NaN")) }
    let positive: (Int) -> Result<Int, AnyError>    = { $0 > 0 ? .success($0) : .failure(AnyError("≤ 0")) }
    let check = parse >=> positive
    check("42")                                       // success(42)
    check("-1")                                       // failure("≤ 0")
    check("abc")                                      // failure("NaN")
}
// learn(monadResult)

// MARK: - Either

func monadEither() {
    let right: Either<String, Int> = .right(5)
    let left:  Either<String, Int> = .left("error")

    right.flatMap { .right($0 * 2) }                               // right(10)
    right.flatMap { _ in Either<String, Int>.left("step failed") } // left("step failed")
    left.flatMap  { Either<String, Int>.right($0 * 2) }            // left("error")

    // bind + operators
    let validate: (Int) -> Either<String, Int> = { $0 > 0 ? .right($0) : .left("non-positive") }
    right >>- validate                                             // right(5)
    left >>- validate                                              // left("error")
    validate -<< right                                             // right(5)
    validate -<< left                                              // left("error")

    // join — outer type must be the nested Either
    Either<String, Either<String, Int>>.join(.right(.right(42)))     // right(42)
    Either<String, Either<String, Int>>.join(.right(.left("inner"))) // left("inner")
    Either<String, Either<String, Int>>.join(.left("outer"))         // left("outer")

    // Kleisli
    let parse:  (String) -> Either<String, Int> = { Int($0).map(Either.right) ?? .left("NaN") }
    let nonneg: (Int) -> Either<String, Int>    = { $0 >= 0 ? .right($0) : .left("negative") }
    let check  = parse >=> nonneg
    check("42")                                       // right(42)
    check("-1")                                       // left("negative")
    check("abc")                                      // left("NaN")

    let checkR = nonneg <=< parse                     // right-to-left, same result
    checkR("42")                                      // right(42)
}
// learn(monadEither)

// MARK: - Reader

struct MonadReaderDB { let users: [Int: String] }

func monadReader() {
    // flatMap — second Reader computed from first result
    let getUser = Reader<MonadReaderDB, String?>.asks { $0.users[1] }
    let greet   = getUser.flatMap { name in
        Reader<MonadReaderDB, String> { _ in name.map { "Hello, \($0)!" } ?? "Unknown" }
    }
    greet.runReader(MonadReaderDB(users: [1: "Alice"]))   // "Hello, Alice!"
    greet.runReader(MonadReaderDB(users: [:]))             // "Unknown"

    // bind + operators
    let addPrefix: (String?) -> Reader<MonadReaderDB, String> = { name in
        Reader { _ in name.map { ">> \($0)" } ?? "Unknown" }
    }
    _ = getUser >>- addPrefix                             // Reader — value left
    _ = addPrefix -<< getUser                             // Reader — fn left

    // join — flatten nested Reader
    let nested = Reader<MonadReaderDB, Reader<MonadReaderDB, String>> { _ in
        Reader { db in db.users[1] ?? "none" }
    }
    Reader<MonadReaderDB, Reader<MonadReaderDB, String>>.join(nested)
        .runReader(MonadReaderDB(users: [1: "Alice"]))    // "Alice"

    // Kleisli — compose Reader-returning functions
    let lookupUser: (Int) -> Reader<MonadReaderDB, String?> = { id in Reader { $0.users[id] } }
    let greetOpt:   (String?) -> Reader<MonadReaderDB, String> = { name in
        Reader { _ in name.map { "Hi, \($0)" } ?? "Unknown" }
    }
    let pipeline  = lookupUser >=> greetOpt
    let pipelineR = greetOpt <=< lookupUser              // right-to-left, same result
    pipeline(1).runReader(MonadReaderDB(users: [1: "Bob"]))   // "Hi, Bob"
    pipelineR(1).runReader(MonadReaderDB(users: [1: "Bob"]))  // "Hi, Bob"
}
// learn(monadReader)

// MARK: - Writer

func monadWriter() {
    // flatMap appends logs via Monoid.combine
    let w = Writer(5, ["start"])
        .flatMap { n in Writer(n + 1, ["added 1"]) }
        .flatMap { n in Writer(n * 2, ["doubled"]) }

    w.evalWriter()                                      // 12
    w.execWriter()                                      // ["start", "added 1", "doubled"]
    w.runWriter()                                       // (12, ["start", "added 1", "doubled"])

    // bind (curried) + operators
    let step: (Int) -> Writer<[String], Int> = { n in Writer(n * 2, ["×2 → \(n * 2)"]) }
    (Writer(3, ["start"]) >>- step).runWriter()         // (6, ["start", "×2 → 6"])
    (step -<< Writer(3, ["start"])).runWriter()         // (6, ["start", "×2 → 6"])

    // join — outer type must wrap the inner Writer
    let nested = Writer(Writer(42, ["inner"]), ["outer"])
    Writer<[String], Writer<[String], Int>>.join(nested).runWriter()  // (42, ["outer", "inner"])

    // Kleisli
    let log:    (Int) -> Writer<[String], Int> = { n in Writer(n, ["saw \(n)"]) }
    let double: (Int) -> Writer<[String], Int> = { n in Writer(n * 2, ["×2 → \(n * 2)"]) }
    let pipeline  = log >=> double
    let pipelineR = double <=< log                      // right-to-left, same result
    pipeline(5).runWriter()                             // (10, ["saw 5", "×2 → 10"])
    pipelineR(5).runWriter()                            // (10, ["saw 5", "×2 → 10"])
}
// learn(monadWriter)

// MARK: - Stateful

func monadStateful() {
    let getState  = Stateful<Int, Int>  { s in s }
    let increment = Stateful<Int, Void> { s in s += 1 }

    // flatMap — threads state automatically
    let readAfterInc = increment.flatMap { _ in getState }
    readAfterInc.runStateful(0)                         // (1, 1)

    // Chain three increments then read
    let thrice = increment
        .flatMap { _ in increment }
        .flatMap { _ in increment }
        .flatMap { _ in getState }
    thrice.runStateful(0)                               // (3, 3)

    // bind + operators
    let step: (()) -> Stateful<Int, Int> = { _ in getState }
    (increment >>- step).runStateful(0)                 // (1, 1) — value left
    (step -<< increment).runStateful(0)                 // (1, 1) — fn left

    // join — outer type must wrap the inner Stateful
    let nested = Stateful<Int, Stateful<Int, Int>> { _ in getState }
    Stateful<Int, Stateful<Int, Int>>.join(nested).runStateful(3)   // (3, 3)

    // Kleisli
    let addN: (Int) -> Stateful<Int, Void> = { n in Stateful { s in s += n } }
    let nextStep: (()) -> Stateful<Int, Void> = { _ in addN(5) }
    let add3then5  = addN >=> nextStep
    let add3then5R = nextStep <=< addN                  // right-to-left, same result
    (add3then5(3).flatMap { _ in getState }).runStateful(0)   // (8, 8)
    (add3then5R(3).flatMap { _ in getState }).runStateful(0)  // (8, 8)
}
// learn(monadStateful)

// MARK: - DeferredTask

func monadDeferredTask() async {
    let fetchId   = DeferredTask { 42 }
    let fetchUser = { @Sendable (id: Int) in DeferredTask { "User #\(id)" } }

    // flatMap — second task depends on first result
    let pipeline = fetchId.flatMap(fetchUser)
    let piped    = fetchId >>- fetchUser       // value left
    let pipedR   = fetchUser -<< fetchId       // fn left

    // join — outer type must wrap the inner DeferredTask
    let nested = DeferredTask { DeferredTask { "hello" } }
    let flat   = DeferredTask<DeferredTask<String>>.join(nested)

    // Kleisli
    let step1: @Sendable (String) -> DeferredTask<Int>    = { s in DeferredTask { s.count } }
    let step2: @Sendable (Int)    -> DeferredTask<String> = { n in DeferredTask { "len: \(n)" } }
    let chain  = step1 >=> step2
    let chainR = step2 <=< step1               // right-to-left, same result

    await pipeline.run()          // "User #42"
    await piped.run()             // "User #42"
    await pipedR.run()            // "User #42"
    await flat.run()              // "hello"
    await chain("hello").run()    // "len: 5"
    await chainR("hello").run()   // "len: 5"
}
// learn(monadDeferredTask)

// MARK: - DeferredStream

func monadDeferredStream() async {
    let stream = DeferredStream {
        AsyncStream<Int> { c in
            for i in 1...3 { c.yield(i) }
            c.finish()
        }
    }

    // flatMap — each element expands into a sub-stream, results flattened (concatMap)
    let expanded = stream.flatMap { n in
        DeferredStream {
            AsyncStream<Int> { c in c.yield(n); c.yield(n * 10); c.finish() }
        }
    }

    // bind + operators
    let expand: @Sendable (Int) -> DeferredStream<Int> = { n in
        DeferredStream { AsyncStream { c in c.yield(n); c.yield(-n); c.finish() } }
    }
    _ = stream >>- expand    // value left
    _ = expand -<< stream    // fn left

    // join — outer type must wrap the inner DeferredStream
    let nested = DeferredStream {
        AsyncStream<DeferredStream<Int>> { c in
            c.yield(DeferredStream { AsyncStream { cont in cont.yield(1); cont.finish() } })
            c.yield(DeferredStream { AsyncStream { cont in cont.yield(2); cont.finish() } })
            c.finish()
        }
    }
    let flat = DeferredStream<DeferredStream<Int>>.join(nested)

    // Kleisli
    let step1: @Sendable (Int) -> DeferredStream<String> = { n in
        DeferredStream { AsyncStream { c in c.yield("n:\(n)"); c.finish() } }
    }
    let step2: @Sendable (String) -> DeferredStream<String> = { s in
        DeferredStream { AsyncStream { c in c.yield(s.uppercased()); c.finish() } }
    }
    let pipeline  = step1 >=> step2
    let pipelineR = step2 <=< step1   // right-to-left, same result

    var expandedResult: [Int] = []
    for await v in expanded { expandedResult.append(v) }
    expandedResult   // [1, 10, 2, 20, 3, 30]

    var flatResult: [Int] = []
    for await v in flat { flatResult.append(v) }
    flatResult   // [1, 2]

    var pipeResult: [String] = []
    for await v in pipeline(5) { pipeResult.append(v) }
    pipeResult    // ["N:5"]

    var pipeRResult: [String] = []
    for await v in pipelineR(5) { pipeRResult.append(v) }
    pipeRResult   // ["N:5"]
}
// learn(monadDeferredStream)

// MARK: - Publisher (Combine)

func monadPublisher() async {
    let pub: AnyPublisher<Int, Never> = Just(42).eraseToAnyPublisher()
    let fetchUser: (Int) -> AnyPublisher<String, Never> = { id in
        Just("User #\(id)").eraseToAnyPublisher()
    }

    // flatMap — second publisher depends on first result (Combine native flatMap)
    let pipeline = pub.flatMap { fetchUser($0) }.eraseToAnyPublisher()
    // bind (curried) + operators
    let piped    = (pub >>- fetchUser).eraseToAnyPublisher()   // value left
    let pipedR   = (fetchUser -<< pub).eraseToAnyPublisher()   // fn left

    // Kleisli
    let step1: (String) -> AnyPublisher<Int, Never>    = { s in Just(s.count).eraseToAnyPublisher() }
    let step2: (Int)    -> AnyPublisher<String, Never> = { n in Just("len:\(n)").eraseToAnyPublisher() }
    let chain  = step1 >=> step2   // (String) -> any Publisher<String, Never>
    let chainR = step2 <=< step1   // right-to-left, same result

    var r1 = [String](), r2 = [String](), r3 = [String]()
    for await v in pipeline.values { r1.append(v) }
    for await v in piped.values    { r2.append(v) }
    for await v in pipedR.values   { r3.append(v) }
    r1   // ["User #42"]
    r2   // ["User #42"]
    r3   // ["User #42"]

    var r4 = [String](), r5 = [String]()
    for await v in chain("hello").eraseToAnyPublisher().values  { r4.append(v) }
    for await v in chainR("hello").eraseToAnyPublisher().values { r5.append(v) }
    r4   // ["len:5"]
    r5   // ["len:5"]
}
// learn(monadPublisher)

//: [Previous](@previous) | [Next](@next)
