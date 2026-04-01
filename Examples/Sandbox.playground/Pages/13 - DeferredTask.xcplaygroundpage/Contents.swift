import FP
import PlaygroundSupport

// ============================================================
// DEFERREDTASK<A>
// run          :: DeferredTask<A> -> async -> A
// eraseToTask  :: DeferredTask<A> -> Task<A, Never>
//
// DeferredTask is the IO monad for Swift async/await.
// It wraps a lazy async computation: nothing executes until
// .run() is explicitly called. You can build, compose, and
// transform DeferredTasks freely — they're just descriptions
// of work, not running computations.
//
// This makes side effects explicit, testable, and composable.
//
// Haskell equivalent: IO a  /  cats-effect IO
// ============================================================

// ---- Uncomment the block below to enable async execution ----
// PlaygroundPage.current.needsIndefiniteExecution = true


// MARK: - Construction & Running

// --- A task that does nothing yet ---
// let task = DeferredTask { 42 }
// // Nothing has run. The closure is stored, not executed.

// --- Run it (must be inside an async context) ---
// Task {
//     let result = await task.run()        // 42 — runs NOW
//     print(result)
//     PlaygroundPage.current.finishExecution()
// }

// --- eraseToTask: fire-and-forget ---
// let t = DeferredTask { print("side effect!") }
// // t.eraseToTask()                       // starts a new Task immediately


// MARK: - Functor (transform the result, still lazy)

// let task = DeferredTask { 5 }

// --- Named function ---
// let doubled = task.fmap { $0 * 2 }      // DeferredTask { 10 } — still not running

// --- Operators ---
// let doubled2 = { $0 * 2 } <£> task      // same
// let doubled3 = task <&> { $0 * 2 }      // same

// Task {
//     let result = await doubled.run()     // 10
//     print(result)
//     PlaygroundPage.current.finishExecution()
// }


// MARK: - Applicative (run two tasks, combine results)

// let taskA = DeferredTask { 3 }
// let taskB = DeferredTask { 4 }

// --- liftA2: both tasks run, results combined ---
// let sumTask = DeferredTask<Int>.liftA2(+)(taskA, taskB)

// Task {
//     let result = await sumTask.run()     // 7
//     print(result)
//     PlaygroundPage.current.finishExecution()
// }

// --- apply ---
// let fnTask = DeferredTask<(Int) -> Int> { { $0 * 10 } }
// let product = fnTask <*> taskA

// Task {
//     let result = await product.run()     // 30
//     print(result)
//     PlaygroundPage.current.finishExecution()
// }


// MARK: - Monad (sequential async work — second step depends on first)

// let fetchId = DeferredTask { 42 }
// let fetchUser: (Int) -> DeferredTask<String> = { id in DeferredTask { "User #\(id)" } }

// --- flatMap ---
// let pipeline = fetchId.flatMap(fetchUser)

// Task {
//     let user = await pipeline.run()      // "User #42"
//     print(user)
//     PlaygroundPage.current.finishExecution()
// }

// --- bind (curried) ---
// let bound = DeferredTask<Int>.bind(fetchUser)(fetchId)

// --- Operators ---
// let piped = fetchId >>- fetchUser        // "User #42"

// --- join: flatten nested DeferredTask ---
// let nested = DeferredTask { DeferredTask { "hello" } }
// // let flat = DeferredTask<String>.join(nested) — awaits the outer, then the inner


// MARK: - Kleisli (compose async functions)

// let step1: (String) -> DeferredTask<Int>    = { s in DeferredTask { s.count } }
// let step2: (Int) -> DeferredTask<String>    = { n in DeferredTask { "length: \(n)" } }
// let step3: (String) -> DeferredTask<String> = { s in DeferredTask { s.uppercased() } }

// let pipeline = step1 >=> step2 >=> step3   // right-associative: step1 then step2 then step3

// Task {
//     let result = await pipeline("hello").run()  // "LENGTH: 5"
//     print(result)
//     PlaygroundPage.current.finishExecution()
// }


// MARK: - Practical: lazy effect sequencing

// struct API {
//     static func authenticate(token: String) -> DeferredTask<Bool> {
//         DeferredTask { token == "secret" }
//     }

//     static func fetchData(userId: Int) -> DeferredTask<[String]> {
//         DeferredTask { ["item1", "item2", "item3"] }
//     }
// }

// let program = API.authenticate(token: "secret")
//     .flatMap { isAuthed -> DeferredTask<[String]> in
//         guard isAuthed else { return DeferredTask { [] } }
//         return API.fetchData(userId: 1)
//     }
//     .fmap { items in "Fetched \(items.count) items" }

// Task {
//     let result = await program.run()     // "Fetched 3 items"
//     print(result)
//     PlaygroundPage.current.finishExecution()
// }

//: [Previous](@previous) | [Next](@next)
