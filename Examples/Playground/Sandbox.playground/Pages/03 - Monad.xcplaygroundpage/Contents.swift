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
    let composed   = Optional<Int>.kleisli(parseInt, nonneg)   // named
    let composedOp = parseInt >=> nonneg                       // operator
    composed("5")   // Optional(5)
    composedOp("5") // Optional(5)
    composed("-1")   // nil
    composed("abc")  // nil

    let reversed   = Optional<Int>.kleisliBack(nonneg, parseInt)   // named, right-to-left
    let reversedOp = nonneg <=< parseInt                           // operator
    reversed("5")   // Optional(5)
    reversedOp("5") // Optional(5)
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
    let split   = Array<Int>.kleisli(digits, doubled)   // named
    let splitOp = digits >=> doubled                    // operator
    split(12)    // [1, 2, 2, 4]
    splitOp(12)  // [1, 2, 2, 4]

    let splitR   = Array<Int>.kleisliBack(doubled, digits)   // named, right-to-left
    let splitROp = doubled <=< digits                        // operator
    splitR(12)   // [1, 2, 2, 4]
    splitROp(12) // [1, 2, 2, 4]
}
// learn(monadArray)

// MARK: - Result

func monadResult() {
    let ok:  Result<Int, AnyError> = .success(5)
    let err: Result<Int, AnyError> = .failure(AnyError("bad"))

    ok.flatMap { $0 > 3 ? .success($0 * 2) : .failure(AnyError("too small")) }   // success(10)
    err.flatMap { .success($0 * 2) }                                              // failure("bad")

    // bind (curried static)
    let fail: (Int) -> Result<Int, AnyError> = { _ in .failure(AnyError("step failed")) }
    Result<Int, AnyError>.bind(fail)(ok)                                         // failure("step failed")
    Result<Int, AnyError>.bind(fail)(err)                                        // failure("bad")

    // Operators
    ok >>- fail                                                                   // failure("step failed")
    err >>- { .success($0 * 2) }                                                  // failure("bad")
    _ = fail -<< ok                                                               // failure("step failed")

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
    let check   = Result<Int, AnyError>.kleisli(parse, positive)   // named
    let checkOp = parse >=> positive                               // operator
    check("42")   // success(42)
    checkOp("42") // success(42)
    check("-1")   // failure("≤ 0")
    check("abc")  // failure("NaN")

    let checkR   = Result<Int, AnyError>.kleisliBack(positive, parse)   // named, right-to-left
    let checkROp = positive <=< parse                                    // operator
    checkR("42")   // success(42)
    checkROp("42") // success(42)
}
// learn(monadResult)

// MARK: - Either

func monadEither() {
    let right: Either<String, Int> = .right(5)
    let left:  Either<String, Int> = .left("error")

    right.flatMap { .right($0 * 2) }                               // right(10)
    right.flatMap { _ in Either<String, Int>.left("step failed") } // left("step failed")
    left.flatMap  { Either<String, Int>.right($0 * 2) }            // left("error")

    // bind (curried static)
    let validate: (Int) -> Either<String, Int> = { $0 > 0 ? .right($0) : .left("non-positive") }
    Either<String, Int>.bind(validate)(right)                                  // right(5)
    Either<String, Int>.bind(validate)(left)                                   // left("error")

    // Operators
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
    let check   = Either<String, Int>.kleisli(parse, nonneg)   // named
    let checkOp = parse >=> nonneg                              // operator
    check("42")   // right(42)
    checkOp("42") // right(42)
    check("-1")   // left("negative")
    check("abc")  // left("NaN")

    let checkR   = Either<String, Int>.kleisliBack(nonneg, parse)   // named, right-to-left
    let checkROp = nonneg <=< parse                                  // operator
    checkR("42")   // right(42)
    checkROp("42") // right(42)
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

    // bind (curried static)
    let addPrefix: (String?) -> Reader<MonadReaderDB, String> = { name in
        Reader { _ in name.map { ">> \($0)" } ?? "Unknown" }
    }
    _ = Reader<MonadReaderDB, String?>.bind(addPrefix)(getUser)   // named
    _ = getUser >>- addPrefix                                       // value left
    _ = addPrefix -<< getUser                                       // fn left

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
    let pipeline    = Reader<MonadReaderDB, String?>.kleisli(lookupUser, greetOpt)        // named
    let pipelineOp  = lookupUser >=> greetOpt                                            // operator
    let pipelineR   = Reader<MonadReaderDB, String?>.kleisliBack(greetOpt, lookupUser)   // named, right-to-left
    let pipelineROp = greetOpt <=< lookupUser                                            // operator
    pipeline(1).runReader(MonadReaderDB(users: [1: "Bob"]))    // "Hi, Bob"
    pipelineOp(1).runReader(MonadReaderDB(users: [1: "Bob"]))  // "Hi, Bob"
    pipelineR(1).runReader(MonadReaderDB(users: [1: "Bob"]))   // "Hi, Bob"
    pipelineROp(1).runReader(MonadReaderDB(users: [1: "Bob"])) // "Hi, Bob"
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

    // bind (curried static)
    let step: (Int) -> Writer<[String], Int> = { n in Writer(n * 2, ["×2 → \(n * 2)"]) }
    Writer<[String], Int>.bind(step)(Writer(3, ["start"])).runWriter()   // (6, ["start", "×2 → 6"])

    // Operators
    (Writer(3, ["start"]) >>- step).runWriter()         // (6, ["start", "×2 → 6"])
    (step -<< Writer(3, ["start"])).runWriter()         // (6, ["start", "×2 → 6"])

    // join — outer type must wrap the inner Writer
    let nested = Writer(Writer(42, ["inner"]), ["outer"])
    Writer<[String], Writer<[String], Int>>.join(nested).runWriter()  // (42, ["outer", "inner"])

    // Kleisli
    let log:    (Int) -> Writer<[String], Int> = { n in Writer(n, ["saw \(n)"]) }
    let double: (Int) -> Writer<[String], Int> = { n in Writer(n * 2, ["×2 → \(n * 2)"]) }
    let pipeline    = Writer<[String], Int>.kleisli(log, double)         // named
    let pipelineOp  = log >=> double                                    // operator
    let pipelineR   = Writer<[String], Int>.kleisliBack(double, log)    // named, right-to-left
    let pipelineROp = double <=< log                                    // operator
    pipeline(5).runWriter()    // (10, ["saw 5", "×2 → 10"])
    pipelineOp(5).runWriter()  // (10, ["saw 5", "×2 → 10"])
    pipelineR(5).runWriter()   // (10, ["saw 5", "×2 → 10"])
    pipelineROp(5).runWriter() // (10, ["saw 5", "×2 → 10"])
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

    // bind (curried static)
    let step: (()) -> Stateful<Int, Int> = { _ in getState }
    Stateful<Int, Void>.bind(step)(increment).runStateful(0)   // (1, 1) — named
    (increment >>- step).runStateful(0)                         // (1, 1) — value left
    (step -<< increment).runStateful(0)                         // (1, 1) — fn left

    // join — outer type must wrap the inner Stateful
    let nested = Stateful<Int, Stateful<Int, Int>> { _ in getState }
    Stateful<Int, Stateful<Int, Int>>.join(nested).runStateful(3)   // (3, 3)

    // Kleisli
    let addN: (Int) -> Stateful<Int, Void> = { n in Stateful { s in s += n } }
    let nextStep: (()) -> Stateful<Int, Void> = { _ in addN(5) }
    let add3then5    = Stateful<Int, Void>.kleisli(addN, nextStep)       // named
    let add3then5Op  = addN >=> nextStep                                  // operator
    let add3then5R   = Stateful<Int, Void>.kleisliBack(nextStep, addN)   // named, right-to-left
    let add3then5ROp = nextStep <=< addN                                  // operator
    (add3then5(3).flatMap { _ in getState }).runStateful(0)    // (8, 8)
    (add3then5Op(3).flatMap { _ in getState }).runStateful(0)  // (8, 8)
    (add3then5R(3).flatMap { _ in getState }).runStateful(0)   // (8, 8)
    (add3then5ROp(3).flatMap { _ in getState }).runStateful(0) // (8, 8)
}
// learn(monadStateful)

// MARK: - Publisher (Combine)

func monadPublisher() async {
    let pub: AnyPublisher<Int, Never> = Just(42).eraseToAnyPublisher()
    let fetchUser: (Int) -> AnyPublisher<String, Never> = { id in
        Just("User #\(id)").eraseToAnyPublisher()
    }

    // flatMap — second publisher depends on first result (Combine native flatMap)
    let pipeline = pub.flatMap { fetchUser($0) }.eraseToAnyPublisher()

    // bind (curried static)
    let bound = AnyPublisher<Int, Never>.bind(fetchUser)(pub).eraseToAnyPublisher()   // named

    // Operators
    let piped  = (pub >>- fetchUser).eraseToAnyPublisher()   // value left
    let pipedR = (fetchUser -<< pub).eraseToAnyPublisher()   // fn left

    // Kleisli
    let step1: (String) -> AnyPublisher<Int, Never>    = { s in Just(s.count).eraseToAnyPublisher() }
    let step2: (Int)    -> AnyPublisher<String, Never> = { n in Just("len:\(n)").eraseToAnyPublisher() }
    let chain   = AnyPublisher<Int, Never>.kleisli(step1, step2)   // named
    let chainOp = step1 >=> step2                                   // operator
    let chainR  = step2 <=< step1                                   // right-to-left operator

    var r1 = [String](), r2 = [String](), r3 = [String](), r4 = [String]()
    for await v in pipeline.values { r1.append(v) }
    for await v in bound.values    { r2.append(v) }
    for await v in piped.values    { r3.append(v) }
    for await v in pipedR.values   { r4.append(v) }
    r1   // ["User #42"]
    r2   // ["User #42"]
    r3   // ["User #42"]
    r4   // ["User #42"]

    var r5 = [String](), r6 = [String](), r7 = [String]()
    for await v in chain("hello").eraseToAnyPublisher().values   { r5.append(v) }
    for await v in chainOp("hello").eraseToAnyPublisher().values { r6.append(v) }
    for await v in chainR("hello").eraseToAnyPublisher().values  { r7.append(v) }
    r5   // ["len:5"]
    r6   // ["len:5"]
    r7   // ["len:5"]
}
// learn(monadPublisher)

//: [Previous](@previous) | [Next](@next)
