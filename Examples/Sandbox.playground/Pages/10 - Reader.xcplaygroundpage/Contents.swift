import FP

// ============================================================
// READER<Environment, Output>
// runReader :: Reader<E, A> -> E -> A
//
// Reader is the dependency injection monad. It wraps a function
// (Environment) -> Output. The environment is threaded through
// automatically — you never pass it explicitly until the very end.
//
// Think of it as a computation that needs an environment to run.
// You describe the whole computation by composing Readers,
// then inject the actual dependencies once at the call site.
//
// Haskell equivalent: Reader / ReaderT
// ============================================================

// MARK: - Construction & Running

// struct AppConfig {
//     let multiplier: Int
//     let greeting: String
// }

// --- Explicit init ---
// let r1 = Reader<AppConfig, Int> { config in config.multiplier * 2 }

// --- Run it (inject the environment) ---
// r1.runReader(AppConfig(multiplier: 3, greeting: "Hi"))   // 6
// r1(AppConfig(multiplier: 3, greeting: "Hi"))             // 6 — callAsFunction


// MARK: - ask and asks (reading from the environment)

// --- ask: returns the whole environment ---
// let getAll = Reader<AppConfig, AppConfig>.ask
// getAll.runReader(AppConfig(multiplier: 3, greeting: "Hi"))  // AppConfig(3, "Hi")

// --- asks: project a value from the environment ---
// let getMultiplier = Reader<AppConfig, Int>.asks(\.multiplier)
// getMultiplier.runReader(AppConfig(multiplier: 5, greeting: "Hi"))   // 5

// let getGreeting = Reader<AppConfig, String>.asks(\.greeting)
// getGreeting.runReader(AppConfig(multiplier: 3, greeting: "Hello")) // "Hello"

// --- asks with a transformation ---
// let doubledMultiplier = Reader<AppConfig, Int>.asks { $0.multiplier * 2 }
// doubledMultiplier.runReader(AppConfig(multiplier: 4, greeting: "Hi"))  // 8


// MARK: - local (run in a modified environment)

// let r = Reader<AppConfig, Int>.asks(\.multiplier)

// --- local: temporarily modify the environment for a sub-computation ---
// let doubled = r.local { AppConfig(multiplier: $0.multiplier * 2, greeting: $0.greeting) }
// r.runReader(AppConfig(multiplier: 3, greeting: "Hi"))       // 3
// doubled.runReader(AppConfig(multiplier: 3, greeting: "Hi")) // 6


// MARK: - Functor

// let r = Reader<AppConfig, Int>.asks(\.multiplier)

// --- Named function (mapReader) ---
// r.mapReader { $0 + 100 }                 // Reader that adds 100 to multiplier
// // .runReader(AppConfig(multiplier: 3, ...)) // 103

// --- fmap (curried static) ---
// Reader<AppConfig, Int>.fmap { $0 + 100 }(r)

// --- Operators ---
// { $0 + 100 } <£> r
// r <&> { $0 + 100 }


// MARK: - Applicative (combine two independent readers)

// struct Config { let x: Int; let y: Int }

// let rx = Reader<Config, Int>.asks(\.x)
// let ry = Reader<Config, Int>.asks(\.y)

// --- liftA2: both readers share the same environment ---
// let sum = Reader<Config, Int>.liftA2(+)(rx, ry)
// sum.runReader(Config(x: 3, y: 4))        // 7

// --- apply ---
// let fn = Reader<Config, (Int) -> Int> { config in { $0 * config.x } }
// (fn <*> ry).runReader(Config(x: 3, y: 4))  // 12 (4 * 3)

// --- seqRight: run both, keep second ---
// (rx *> ry).runReader(Config(x: 3, y: 4))  // 4


// MARK: - Monad (sequential, each step can depend on previous result)

// struct DB { let users: [Int: String] }

// let getUser = Reader<DB, String?>.asks { db in db.users[1] }

// --- flatMap: second reader computed from first result ---
// let greet = getUser.flatMap { name in
//     Reader<DB, String> { _ in name.map { "Hello, \($0)!" } ?? "User not found" }
// }
// greet.runReader(DB(users: [1: "Alice"]))   // "Hello, Alice!"
// greet.runReader(DB(users: [2: "Bob"]))     // "User not found"

// --- bind (curried) ---
// let r = Reader<DB, String?>.asks { $0.users[1] }
// Reader<DB, String?>.bind { name in Reader { _ in name.map { $0.uppercased() } } }(r)

// --- Kleisli: compose two Reader-returning functions ---
// let lookupUser: (Int) -> Reader<DB, String?> = { id in Reader { $0.users[id] } }
// let lookupGreeting: (String?) -> Reader<DB, String> = { name in
//     Reader { _ in name.map { "Hi, \($0)" } ?? "Unknown" }
// }
// let pipeline = lookupUser >=> lookupGreeting
// pipeline(1).runReader(DB(users: [1: "Alice"]))  // "Hi, Alice"


// MARK: - Practical: dependency injection

// protocol Logger { func log(_ message: String) }
// protocol Database { func fetch(_ id: Int) -> String? }

// struct AppEnv {
//     let logger: Logger
//     let database: Database
// }

// --- Compose a use-case from two concerns without passing dependencies manually ---
// let fetchAndLog = Reader<AppEnv, String?> { env in
//     let result = env.database.fetch(42)
//     env.logger.log("fetched: \(result ?? "nil")")
//     return result
// }

// --- Inject at the call site ---
// fetchAndLog.runReader(AppEnv(logger: myLogger, database: myDB))

//: [Previous](@previous) | [Next](@next)
