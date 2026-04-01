import FP

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

func learnMonadOptional() {
    let x: Int? = 5

    // flatMap (instance)
    print(x.flatMap { $0 > 3 ? .some($0 * 2) : .none })    // Optional(10)
    print(x.flatMap { _ in Int?.none })                      // nil

    // bind (curried static)
    let positive: (Int) -> Int? = { $0 > 0 ? .some($0) : .none }
    print(Optional<Int>.bind(positive)(x))                   // Optional(5)
    print(Optional<Int>.bind(positive)(nil))                 // nil

    // Operators
    print(x >>- positive)                                    // Optional(5) — value left
    print(positive -<< x)                                    // Optional(5) — fn left

    // join — flatten nested Optional
    print(Optional<Int>.join(.some(.some(42))))              // Optional(42)
    print(Optional<Int>.join(.some(.none)))                  // nil

    // Kleisli — compose two (a -> m b) arrows
    let parseInt: (String) -> Int? = { Int($0) }
    let nonneg:   (Int) -> Int?    = { $0 >= 0 ? .some($0) : .none }
    let composed  = parseInt >=> nonneg
    print(composed("5"))                                     // Optional(5)
    print(composed("-1"))                                    // nil
    print(composed("abc"))                                   // nil

    let reversed  = nonneg <=< parseInt                     // right-to-left, same result
    print(reversed("5"))                                     // Optional(5)
}
// learnMonadOptional()

// MARK: - Array

func learnMonadArray() {
    // flatMap — expand each element, flatten
    print([1, 2, 3].flatMap { [$0, $0 * 10] })              // [1, 10, 2, 20, 3, 30]

    // bind (curried)
    let expand: (Int) -> [Int] = { [$0, -$0] }
    print(Array<Int>.bind(expand)([1, 2, 3]))               // [1, -1, 2, -2, 3, -3]
    print([1, 2, 3] >>- expand)                             // [1, -1, 2, -2, 3, -3]

    // join — flatten nested array
    print(Array<Int>.join([[1, 2], [3], [4, 5]]))           // [1, 2, 3, 4, 5]

    // Kleisli
    let digits:  (Int) -> [Int] = { n in n < 10 ? [n] : [n / 10, n % 10] }
    let doubled: (Int) -> [Int] = { [$0, $0 * 2] }
    let split = digits >=> doubled
    print(split(12))                                         // [1, 2, 2, 4]
}
// learnMonadArray()

// MARK: - Result

func learnMonadResult() {
    let ok:  Result<String, Int> = .success(5)
    let err: Result<String, Int> = .failure("bad")

    print(ok.flatMap { $0 > 3 ? .success($0 * 2) : .failure("too small") })  // success(10)
    print(ok >>- { _ in Result<String, Int>.failure("step failed") })         // failure("step failed")
    print(err >>- { .success($0 * 2) })                                       // failure("bad")

    // Kleisli
    let parse:    (String) -> Result<String, Int> = { Int($0).map(Result.success) ?? .failure("NaN") }
    let positive: (Int) -> Result<String, Int>    = { $0 > 0 ? .success($0) : .failure("≤ 0") }
    let check = parse >=> positive
    print(check("42"))                                       // success(42)
    print(check("-1"))                                       // failure("≤ 0")
    print(check("abc"))                                      // failure("NaN")
}
// learnMonadResult()

// MARK: - Either

func learnMonadEither() {
    let right: Either<String, Int> = .right(5)
    let left:  Either<String, Int> = .left("error")

    print(right.flatMap { .right($0 * 2) })                 // right(10)
    print(right.flatMap { _ in Either<String, Int>.left("step failed") }) // left("step failed")
    print(left >>- { Either<String, Int>.right($0 * 2) })   // left("error")

    // Kleisli
    let parse:   (String) -> Either<String, Int> = { Int($0).map(Either.right) ?? .left("NaN") }
    let nonneg:  (Int) -> Either<String, Int>    = { $0 >= 0 ? .right($0) : .left("negative") }
    let check = parse >=> nonneg
    print(check("42"))                                       // right(42)
    print(check("-1"))                                       // left("negative")
    print(check("abc"))                                      // left("NaN")
}
// learnMonadEither()

// MARK: - Reader

struct MonadReaderDB { let users: [Int: String] }

func learnMonadReader() {
    // flatMap — second Reader computed from first result
    let getUser = Reader<MonadReaderDB, String?>.asks { $0.users[1] }
    let greet   = getUser.flatMap { name in
        Reader<MonadReaderDB, String> { _ in name.map { "Hello, \($0)!" } ?? "Unknown" }
    }
    print(greet.runReader(MonadReaderDB(users: [1: "Alice"])))  // "Hello, Alice!"
    print(greet.runReader(MonadReaderDB(users: [:])))           // "Unknown"

    // Kleisli — compose Reader-returning functions
    let lookupUser: (Int) -> Reader<MonadReaderDB, String?> = { id in Reader { $0.users[id] } }
    let greetOpt:   (String?) -> Reader<MonadReaderDB, String> = { name in
        Reader { _ in name.map { "Hi, \($0)" } ?? "Unknown" }
    }
    let pipeline = lookupUser >=> greetOpt
    print(pipeline(1).runReader(MonadReaderDB(users: [1: "Bob"]))) // "Hi, Bob"
}
// learnMonadReader()

// MARK: - Writer

func learnMonadWriter() {
    // flatMap appends logs via Monoid.combine
    let w = Writer(5, ["start"])
        .flatMap { n in Writer(n + 1, ["added 1"]) }
        .flatMap { n in Writer(n * 2, ["doubled"]) }

    print(w.evalWriter())                                    // 12
    print(w.execWriter())                                    // ["start", "added 1", "doubled"]
    print(w.runWriter())                                     // (12, ["start", "added 1", "doubled"])

    // bind (curried)
    let step: (Int) -> Writer<[String], Int> = { n in Writer(n * 2, ["×2 → \(n * 2)"]) }
    print((Writer(3, ["start"]) >>- step).runWriter())      // (6, ["start", "×2 → 6"])
}
// learnMonadWriter()

// MARK: - Stateful

func learnMonadStateful() {
    let getState  = Stateful<Int, Int>  { s in s }
    let increment = Stateful<Int, Void> { s in s += 1 }

    // flatMap — threads state automatically
    let readAfterInc = increment.flatMap { _ in getState }
    print(readAfterInc.runStateful(0))                       // (1, 1)

    // Chain three increments then read
    let thrice = increment.flatMap { _ in increment }.flatMap { _ in increment }.flatMap { _ in getState }
    print(thrice.runStateful(0))                             // (3, 3)

    // Kleisli
    let addN: (Int) -> Stateful<Int, Void> = { n in Stateful { s in s += n } }
    let add3then5 = addN >=> { _ in addN(5) }
    print((add3then5(3).flatMap { _ in getState }).runStateful(0))  // (8, 8)
}
// learnMonadStateful()

// MARK: - DeferredTask

func learnMonadDeferredTask() {
    let fetchId   = DeferredTask { 42 }
    let fetchUser = { (id: Int) in DeferredTask { "User #\(id)" } }

    // flatMap — second task depends on first result
    let pipeline  = fetchId.flatMap(fetchUser)

    // Kleisli
    let step1: (String) -> DeferredTask<Int>    = { s in DeferredTask { s.count } }
    let step2: (Int) -> DeferredTask<String>    = { n in DeferredTask { "len: \(n)" } }
    let chain  = step1 >=> step2

    Task {
        print(await pipeline.run())                         // "User #42"
        print(await chain("hello").run())                   // "len: 5"
        print(await (fetchId >>- fetchUser).run())          // "User #42"
    }
}
// learnMonadDeferredTask()

//: [Previous](@previous) | [Next](@next)
