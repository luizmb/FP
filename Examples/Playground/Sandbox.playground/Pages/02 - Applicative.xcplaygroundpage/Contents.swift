import Combine
import FP

// ============================================================
// APPLICATIVE  —  liftA2 :: (a -> b -> c) -> f a -> f b -> f c
//
// Combine independent effects. Unlike Monad, neither value
// depends on the other — they can be evaluated in any order.
// Laws: identity, composition, homomorphism, interchange.
// ============================================================

// MARK: - Optional

func applicativeOptional() {
    let x: Int? = 3
    let y: Int? = 4
    let none: Int? = nil

    // liftA2 — combine two independents with a binary fn
    Optional<Int>.liftA2(+)(x, y) // Optional(7)
    Optional<Int>.liftA2(+)(x, none) // nil — any nil propagates

    // apply — wrapped function applied to wrapped value
    let fn: ((Int) -> Int)? = .some { $0 * 2 }
    let noFn: ((Int) -> Int)? = .none
    Optional.apply(fn, x) // Optional(6)
    Optional.apply(noFn, x) // nil — nil fn propagates
    fn <*> x // Optional(6) — operator
    fn <*> none // nil
    noFn <*> x // nil

    // seqRight / seqLeft — run both, discard one side
    x.seqRight(y) // Optional(4)
    none.seqRight(y) // nil
    x *> y // Optional(4) — operator
    none *> y // nil
    x.seqLeft(y) // Optional(3)
    x.seqLeft(none) // nil
    x <* y // Optional(3) — operator
    x <* none // nil — none propagates

    // zip
    Optional<(Int, Int)>.zip(x, y) // Optional((3, 4))
    Optional<(Int, Int)>.zip(x, none) // nil
}

// learn(applicativeOptional)

// MARK: - Array

func applicativeArray() {
    let xs = [1, 2, 3]
    let ys = [10, 20]

    // liftA2 — cartesian product mapped through a binary fn
    Array<Int>.liftA2(+)(xs, ys) // [11, 21, 12, 22, 13, 23]

    // apply — each fn applied to each value
    let fns: [(Int) -> Int] = [{ $0 + 1 }, { $0 * 2 }]
    fns <*> xs // [2, 3, 4, 2, 4, 6]

    // seqRight / seqLeft
    xs *> ys // [10, 20, 10, 20, 10, 20]
    xs <* ys // [1, 1, 2, 2, 3, 3]
}

// learn(applicativeArray)

// MARK: - Result

func applicativeResult() {
    let ok1: Result<Int, AnyError> = .success(3)
    let ok2: Result<Int, AnyError> = .success(4)
    let err: Result<Int, AnyError> = .failure(AnyError("oops"))

    Result<Int, AnyError>.liftA2(+)(ok1, ok2) // success(7)
    Result<Int, AnyError>.liftA2(+)(ok1, err) // failure(AnyError("oops")) — short-circuits

    let fn: Result<(Int) -> Int, AnyError> = .success { $0 * 2 }
    let errFn: Result<(Int) -> Int, AnyError> = .failure(AnyError("no fn"))
    fn <*> ok1 // success(6)
    fn <*> err // failure(AnyError("oops"))
    errFn <*> ok1 // failure(AnyError("no fn"))

    ok1 *> ok2 // success(4)
    ok1 *> err // failure(AnyError("oops"))
    ok1 <* ok2 // success(3)
    ok1 <* err // failure(AnyError("oops"))
}

// learn(applicativeResult)

// MARK: - Either

func applicativeEither() {
    let r1: Either<String, Int> = .right(3)
    let r2: Either<String, Int> = .right(4)
    let l1: Either<String, Int> = .left("fail")

    Either<String, Int>.liftA2(+)(r1, r2) // right(7)
    Either<String, Int>.liftA2(+)(r1, l1) // left("fail") — short-circuits

    let fn: Either<String, (Int) -> Int> = .right { $0 + 10 }
    let errFn: Either<String, (Int) -> Int> = .left("no fn")
    fn <*> r1 // right(13)
    fn <*> l1 // left("fail")
    errFn <*> r1 // left("no fn")

    r1 *> r2 // right(4)
    l1 *> r2 // left("fail")
    r1 <* r2 // right(3)
    l1 <* r2 // left("fail")
}

// learn(applicativeEither)

// MARK: - Validation (accumulates ALL errors — the key difference)

func applicativeValidation() {
    let ok1: Validation<[String], Int> = .success(3)
    let ok2: Validation<[String], Int> = .success(4)
    let e1: Validation<[String], Int> = .failure(["name is empty"])
    let e2: Validation<[String], Int> = .failure(["age is negative"])

    // liftA2 — collects ALL errors, not just the first
    Validation<[String], Int>.liftA2(+)(ok1, ok2) // success(7)
    Validation<[String], Int>.liftA2(+)(e1, ok2) // failure(["name is empty"])
    Validation<[String], Int>.liftA2(+)(e1, e2)
    // failure(["name is empty", "age is negative"]) ← BOTH errors!

    // Compare: Either short-circuits on first error
    let l1: Either<[String], Int> = .left(["name is empty"])
    let l2: Either<[String], Int> = .left(["age is negative"])
    Either<[String], Int>.liftA2(+)(l1, l2)
    // left(["name is empty"]) ← only first!

    // zip — accumulate errors across fields
    Validation<[String], (Int, Int)>.zip(ok1, ok2) // success((3, 4))
    Validation<[String], (Int, Int)>.zip(e1, e2) // failure(["name is empty", "age is negative"])

    // zip3 — three fields
    let e3: Validation<[String], String> = .failure(["email invalid"])
    Validation<[String], (Int, Int, String)>.zip3(e1, e2, e3)
    // failure(["name is empty", "age is negative", "email invalid"])
}

// learn(applicativeValidation)

// MARK: - Reader

struct ApplicativeReaderEnv { let x: Int; let y: Int }

func applicativeReader() {
    let rx = Reader<ApplicativeReaderEnv, Int>.asks(\.x)
    let ry = Reader<ApplicativeReaderEnv, Int>.asks(\.y)

    // liftA2 — both readers share the same env, results combined
    let sum = Reader<ApplicativeReaderEnv, Int>.liftA2(+)(rx, ry)
    sum.runReader(ApplicativeReaderEnv(x: 3, y: 4)) // 7

    // seqRight — run both, keep second
    let keepY = rx *> ry
    keepY.runReader(ApplicativeReaderEnv(x: 3, y: 4)) // 4
}

// learn(applicativeReader)

// MARK: - Writer

func applicativeWriter() {
    let w1 = Writer(3, ["got 3"])
    let w2 = Writer(4, ["got 4"])

    // liftA2 — both run, logs appended left-to-right
    Writer<[String], Int>.liftA2(+)(w1, w2).runWriter() // (7, ["got 3", "got 4"])

    // apply — wrapped function applied to wrapped value
    let wf: Writer<[String], (Int) -> String> = Writer({ n in "val:\(n)" }, ["fn"])
    (wf <*> w1).runWriter() // ("val:3", ["fn", "got 3"])

    // seqRight / seqLeft — run both, keep one side; logs always appended
    (w1 *> w2).runWriter() // (4, ["got 3", "got 4"])
    (w1 <* w2).runWriter() // (3, ["got 3", "got 4"])

    // zip
    Writer<[String], (Int, Int)>.zip(w1, w2).runWriter() // ((3, 4), ["got 3", "got 4"])
}

// learn(applicativeWriter)

// MARK: - Stateful

func applicativeStateful() {
    // NOTE: unlike Optional/Array, Stateful's applicative threads state left-to-right —
    // each computation sees the state mutated by previous ones.
    let readState = Stateful<Int, Int> { s in s }
    let addOne = Stateful<Int, Int> { s in s += 1; return s }

    // liftA2 — state threaded: readState sees 3, addOne increments to 4
    Stateful<Int, Int>.liftA2(+)(readState, addOne).runStateful(3) // (7, 4) — 3+4=7, state=4

    // apply — wrapped function applied to wrapped value
    let fnSt: Stateful<Int, (Int) -> String> = Stateful { s in
        let s = s
        return { n in "s:\(s),n:\(n)" }
    }
    (fnSt <*> readState).eval(7) // "s:7,n:7"

    // seqRight / seqLeft
    let incr = Stateful<Int, Void> { s in s += 1 }
    (incr *> readState).eval(0) // 1 (incr ran first, then read)
    (readState <* incr).eval(5) // 5 (readState result kept; state becomes 6)

    // zip
    Stateful<Int, (Int, Int)>.zip(readState, addOne).runStateful(3) // ((3, 4), 4)
}

// learn(applicativeStateful)

// MARK: - Publisher (Combine)

func applicativePublisher() async {
    let pub1: AnyPublisher<Int, Never> = Just(3).eraseToAnyPublisher()
    let pub2: AnyPublisher<Int, Never> = Just(4).eraseToAnyPublisher()

    // liftA2 — zip-based: pair the single elements, apply fn
    let sumPub = AnyPublisher<Int, Never>.liftA2(+)(pub1, pub2).eraseToAnyPublisher()

    // apply — wrapped function applied to wrapped value
    let fnPub = Just { (n: Int) in n * 2 }.eraseToAnyPublisher()
    let applied = (fnPub <*> pub1).eraseToAnyPublisher()

    // seqRight / seqLeft
    let seqR = (pub1 *> pub2).eraseToAnyPublisher()
    let seqL = (pub1 <* pub2).eraseToAnyPublisher()

    // zip
    let zipped = AnyPublisher<(Int, Int), Never>.zip(pub1, pub2).eraseToAnyPublisher()

    var r1 = [Int](), r2 = [Int](), r3 = [Int](), r4 = [Int]()
    var r5 = [(Int, Int)]()
    for await v in sumPub.values {
        r1.append(v)
    }
    for await v in applied.values {
        r2.append(v)
    }
    for await v in seqR.values {
        r3.append(v)
    }
    for await v in seqL.values {
        r4.append(v)
    }
    for await v in zipped.values {
        r5.append(v)
    }
    r1 // [7]
    r2 // [6]
    r3 // [4]
    r4 // [3]
    r5 // [(3, 4)]
}

// learn(applicativePublisher)

//: [Previous](@previous) | [Next](@next)
