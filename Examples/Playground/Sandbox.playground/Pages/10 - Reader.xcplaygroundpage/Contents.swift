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

func learnReaderConstruction() {
    let r = Reader<AppConfig, Int> { config in config.multiplier * 2 }

    // Run — inject the environment
    r.runReader(AppConfig(multiplier: 3, greeting: "Hi"))   // 6
    r(AppConfig(multiplier: 5, greeting: "Hi"))             // 10 — callAsFunction
}
// learnReaderConstruction()

// MARK: - ask / asks / local

func learnReaderAsk() {
    // ask — return the whole environment
    let getAll = Reader<AppConfig, AppConfig>.ask
    getAll.runReader(AppConfig(multiplier: 3, greeting: "Hi")).multiplier   // 3

    // asks — project a value
    let getMultiplier = Reader<AppConfig, Int>.asks(\.multiplier)
    let getGreeting   = Reader<AppConfig, String>.asks(\.greeting)
    getMultiplier.runReader(AppConfig(multiplier: 5, greeting: "Hi"))       // 5
    getGreeting.runReader(AppConfig(multiplier: 3, greeting: "Hello"))      // "Hello"

    // asks with transformation
    let doubled = Reader<AppConfig, Int>.asks { $0.multiplier * 2 }
    doubled.runReader(AppConfig(multiplier: 4, greeting: "Hi"))             // 8

    // local — run in a modified environment
    let r = Reader<AppConfig, Int>.asks(\.multiplier)
    let tripled = r.local { AppConfig(multiplier: $0.multiplier * 3, greeting: $0.greeting) }
    r.runReader(AppConfig(multiplier: 3, greeting: "Hi"))                   // 3
    tripled.runReader(AppConfig(multiplier: 3, greeting: "Hi"))             // 9
}
// learnReaderAsk()

// MARK: - Functor

func learnReaderFunctor() {
    let r = Reader<AppConfig, Int>.asks(\.multiplier)

    let shifted = r.mapReader { $0 + 100 }
    shifted.runReader(AppConfig(multiplier: 3, greeting: "Hi"))    // 103

    let withOp = { $0 + 100 } <£> r
    withOp.runReader(AppConfig(multiplier: 3, greeting: "Hi"))     // 103
}
// learnReaderFunctor()

// MARK: - Applicative

struct ReaderEnvXY { let x: Int; let y: Int }

func learnReaderApplicative() {
    let rx = Reader<ReaderEnvXY, Int>.asks(\.x)
    let ry = Reader<ReaderEnvXY, Int>.asks(\.y)

    // liftA2 — both readers share the same env
    let sum = Reader<ReaderEnvXY, Int>.liftA2(+)(rx, ry)
    sum.runReader(ReaderEnvXY(x: 3, y: 4))                            // 7

    // apply
    let fn = Reader<ReaderEnvXY, (Int) -> Int> { env in { $0 * env.x } }
    (fn <*> ry).runReader(ReaderEnvXY(x: 3, y: 4))                   // 12

    // seqRight
    (rx *> ry).runReader(ReaderEnvXY(x: 3, y: 4))                    // 4
}
// learnReaderApplicative()

// MARK: - Monad

struct ReaderDB { let users: [Int: String] }

func learnReaderMonad() {
    let getUser = Reader<ReaderDB, String?>.asks { $0.users[1] }

    // flatMap — second Reader computed from first result
    let greet = getUser.flatMap { name in
        Reader<ReaderDB, String> { _ in name.map { "Hello, \($0)!" } ?? "Unknown" }
    }
    greet.runReader(ReaderDB(users: [1: "Alice"]))                     // "Hello, Alice!"
    greet.runReader(ReaderDB(users: [:]))                              // "Unknown"

    // Kleisli
    let lookupUser:  (Int) -> Reader<ReaderDB, String?> = { id in Reader { $0.users[id] } }
    let greetOpt: (String?) -> Reader<ReaderDB, String> = { name in
        Reader { _ in name.map { "Hi, \($0)" } ?? "Unknown" }
    }
    let pipeline = lookupUser >=> greetOpt
    pipeline(1).runReader(ReaderDB(users: [1: "Bob"]))                 // "Hi, Bob"
}
// learnReaderMonad()

//: [Previous](@previous) | [Next](@next)
