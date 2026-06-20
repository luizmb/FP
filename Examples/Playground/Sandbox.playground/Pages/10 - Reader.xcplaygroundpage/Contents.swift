import FP

// ============================================================
// READER<Environment, Output>
//
// The dependency injection monad. Wraps (Environment) -> Output.
// Thread dependencies automatically — inject once at the edge.
// ============================================================

struct AppConfig {
    let multiplier: Int
    let greeting: String
}

// MARK: - Construction & Running

func readerConstruction() {
    let r = Reader<AppConfig, Int> { config in config.multiplier * 2 }

    // Run — inject the environment
    r.runReader(AppConfig(multiplier: 3, greeting: "Hi")) // 6
    r(AppConfig(multiplier: 5, greeting: "Hi")) // 10 — callAsFunction
}

// learn(readerConstruction)

// MARK: - ask / asks / local

func readerAsk() {
    // ask — return the whole environment
    let getAll = Reader<AppConfig, AppConfig>.ask
    getAll.runReader(AppConfig(multiplier: 3, greeting: "Hi")).multiplier // 3

    // asks — project a value
    let getMultiplier = Reader<AppConfig, Int>.asks(\.multiplier)
    let getGreeting = Reader<AppConfig, String>.asks(\.greeting)
    getMultiplier.runReader(AppConfig(multiplier: 5, greeting: "Hi")) // 5
    getGreeting.runReader(AppConfig(multiplier: 3, greeting: "Hello")) // "Hello"

    // asks with transformation
    let doubled = Reader<AppConfig, Int>.asks { $0.multiplier * 2 }
    doubled.runReader(AppConfig(multiplier: 4, greeting: "Hi")) // 8

    // local — run in a modified environment
    let r = Reader<AppConfig, Int>.asks(\.multiplier)
    let tripled = r.local { AppConfig(multiplier: $0.multiplier * 3, greeting: $0.greeting) }
    r.runReader(AppConfig(multiplier: 3, greeting: "Hi")) // 3
    tripled.runReader(AppConfig(multiplier: 3, greeting: "Hi")) // 9
}

// learn(readerAsk)

// MARK: - Functor

func readerFunctor() {
    let r = Reader<AppConfig, Int>.asks(\.multiplier)

    // Named forms
    let shifted = r.mapReader { $0 + 100 } // instance
    let shifted2 = Reader<AppConfig, Int>.fmap { $0 + 100 }(r) // static curried
    shifted.runReader(AppConfig(multiplier: 3, greeting: "Hi")) // 103
    shifted2.runReader(AppConfig(multiplier: 3, greeting: "Hi")) // 103

    // Operators
    let env = AppConfig(multiplier: 3, greeting: "Hi")
    _ = { $0 + 100 } <£> r // fn left
    (r <&> { $0 + 100 }).runReader(env) // 103 — value left
    (r £> 0).runReader(env) // 0   — replace
    (0 <£ r).runReader(env) // 0   — flipped
}

// learn(readerFunctor)

// MARK: - Applicative

struct ReaderEnvXY { let x: Int; let y: Int }

func readerApplicative() {
    let rx = Reader<ReaderEnvXY, Int>.asks(\.x)
    let ry = Reader<ReaderEnvXY, Int>.asks(\.y)
    let env = ReaderEnvXY(x: 3, y: 4)

    // liftA2 — both readers share the same env
    let sum = Reader<ReaderEnvXY, Int>.liftA2(+)(rx, ry)
    sum.runReader(env) // 7

    // apply (named + operator)
    let fn = Reader<ReaderEnvXY, (Int) -> Int> { e in { $0 * e.x } }
    Reader<ReaderEnvXY, Int>.apply(fn, ry).runReader(env) // 12
    (fn <*> ry).runReader(env) // 12

    // seqRight / seqLeft (named + operator)
    rx.seqRight(ry).runReader(env) // 4
    (rx *> ry).runReader(env) // 4
    rx.seqLeft(ry).runReader(env) // 3
    (rx <* ry).runReader(env) // 3
}

// learn(readerApplicative)

// MARK: - Monad

struct ReaderDB { let users: [Int: String] }

func readerMonad() {
    let getUser = Reader<ReaderDB, String?>.asks { $0.users[1] }

    // flatMap — second Reader computed from first result
    let greet = getUser.flatMap { name in
        Reader<ReaderDB, String> { _ in name.map { "Hello, \($0)!" } ?? "Unknown" }
    }
    greet.runReader(ReaderDB(users: [1: "Alice"])) // "Hello, Alice!"
    greet.runReader(ReaderDB(users: [:])) // "Unknown"

    // bind (curried static) + operators
    let addPrefix: (String?) -> Reader<ReaderDB, String> = { name in
        Reader { _ in name.map { ">> \($0)" } ?? "Unknown" }
    }
    _ = Reader<ReaderDB, String?>.bind(addPrefix)(getUser) // named
    _ = getUser >>- addPrefix // value left
    _ = addPrefix -<< getUser // fn left

    // Kleisli
    let lookupUser: (Int) -> Reader<ReaderDB, String?> = { id in Reader { $0.users[id] } }
    let greetOpt: (String?) -> Reader<ReaderDB, String> = { name in
        Reader { _ in name.map { "Hi, \($0)" } ?? "Unknown" }
    }
    let pipeline = Reader<ReaderDB, String?>.kleisli(lookupUser, greetOpt) // named
    let pipelineOp = lookupUser >=> greetOpt // operator
    let pipelineR = Reader<ReaderDB, String?>.kleisliBack(greetOpt, lookupUser) // named, right-to-left
    let pipelineROp = greetOpt <=< lookupUser // operator
    pipeline(1).runReader(ReaderDB(users: [1: "Bob"])) // "Hi, Bob"
    pipelineOp(1).runReader(ReaderDB(users: [1: "Bob"])) // "Hi, Bob"
    pipelineR(1).runReader(ReaderDB(users: [1: "Bob"])) // "Hi, Bob"
    pipelineROp(1).runReader(ReaderDB(users: [1: "Bob"])) // "Hi, Bob"
}

// learn(readerMonad)

// MARK: - Comonad (requires Environment: Monoid)

struct StringEnv: Monoid {
    let value: String
    static let identity = StringEnv(value: "")
    static func combine(_ a: StringEnv, _ b: StringEnv) -> StringEnv {
        StringEnv(value: a.value + b.value)
    }
}

func readerComonad() {
    // extract :: Reader Env A -> A  (uses Monoid identity as input)
    let r = Reader<StringEnv, Int> { env in env.value.count }
    r.extract // 0 (identity is "")

    // extend :: (Reader Env A -> B) -> Reader Env A -> Reader Env B
    // For each outer env e, builds a "shifted" reader that appends e before running
    let lengthPlusPrefix = r.extend { shifted in shifted.runReader(StringEnv(value: "hi")) }
    lengthPlusPrefix.runReader(StringEnv(value: "")) // 2 (prefix "hi" = 2 chars)

    // Named static form
    let withStatic = Reader<StringEnv, Int>.extend { shifted in shifted.runReader(StringEnv(value: "!")) }(r)
    withStatic.runReader(StringEnv(value: "")) // 1

    // coflatMap — same as extend, value-first argument order
    let doubled = r.coflatMap { shifted in shifted.runReader(StringEnv(value: "ab")) * 2 }
    doubled.runReader(StringEnv(value: "")) // 4

    // duplicate — wraps r in an outer Reader; inner reader appends environments
    let dup = r.duplicate
    dup.runReader(StringEnv(value: "hi")).runReader(StringEnv(value: "!")) // 3 ("hi" + "!" = 3)

    // ->> operator (infixl 1) — r ->> f  =  extend f r
    let withOp = r ->> { shifted in shifted.runReader(StringEnv(value: "xyz")) }
    withOp.runReader(StringEnv(value: "")) // 3

    // <<- operator (infixr 1) — f <<- r  =  extend f r
    let withOpR = { (shifted: Reader<StringEnv, Int>) in shifted.runReader(StringEnv(value: "ab")) } <<- r
    withOpR.runReader(StringEnv(value: "")) // 2
}

// learn(readerComonad)

//: [Previous](@previous) | [Next](@next)
