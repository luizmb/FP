import FP
import PlaygroundSupport

// ============================================================
// DEFERREDTASK<A>
//
// Lazy async computation — nothing runs until .run() is called.
// Descriptions of work, not running work. Like Haskell's IO.
// Uncomment PlaygroundPage line below to capture async output.
// ============================================================

// PlaygroundPage.current.needsIndefiniteExecution = true

// MARK: - Construction & Running

func learnDeferredTaskConstruction() {
    let task = DeferredTask { 42 }
    // Nothing has executed yet. Only .run() triggers the closure.

    let eager = Task {
        let result = await task.run()
        result   // 42
    }
    _ = eager
}
// learnDeferredTaskConstruction()

// MARK: - Functor

func learnDeferredTaskFunctor() {
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
// learnDeferredTaskFunctor()

// MARK: - Applicative

func learnDeferredTaskApplicative() {
    let taskA = DeferredTask { 3 }
    let taskB = DeferredTask { 4 }

    // liftA2 — both run, results combined
    let sumTask = DeferredTask<Int>.liftA2(+)(taskA, taskB)

    // apply
    let fnTask  = DeferredTask<(Int) -> Int> { { $0 * 10 } }
    let product = fnTask <*> taskA

    Task {
        await sumTask.run()    // 7
        await product.run()    // 30
    }
}
// learnDeferredTaskApplicative()

// MARK: - Monad

func learnDeferredTaskMonad() {
    let fetchId   = DeferredTask { 42 }
    let fetchUser = { (id: Int) in DeferredTask { "User #\(id)" } }

    // flatMap — second task depends on first result
    let pipeline  = fetchId.flatMap(fetchUser)

    // bind + operator
    let piped     = fetchId >>- fetchUser

    // join — flatten nested DeferredTask
    let nested    = DeferredTask { DeferredTask { "hello" } }
    let flat      = DeferredTask<String>.join(nested)

    Task {
        await pipeline.run()   // "User #42"
        await piped.run()      // "User #42"
        await flat.run()       // "hello"
    }
}
// learnDeferredTaskMonad()

// MARK: - Kleisli

func learnDeferredTaskKleisli() {
    let countChars: (String) -> DeferredTask<Int>    = { s in DeferredTask { s.count } }
    let describe:   (Int) -> DeferredTask<String>    = { n in DeferredTask { "length: \(n)" } }
    let shout:      (String) -> DeferredTask<String> = { s in DeferredTask { s.uppercased() } }

    let pipeline = countChars >=> describe >=> shout

    Task {
        await pipeline("hello").run()   // "LENGTH: 5"
    }
}
// learnDeferredTaskKleisli()

// MARK: - Practical: lazy effect pipeline

func learnDeferredTaskPractical() {
    func authenticate(token: String) -> DeferredTask<Bool> {
        DeferredTask { token == "secret" }
    }
    func fetchData() -> DeferredTask<[String]> {
        DeferredTask { ["item1", "item2", "item3"] }
    }

    let program = authenticate(token: "secret")
        .flatMap { isAuthed in
            isAuthed ? fetchData() : DeferredTask { [] }
        }
        .fmap { items in "Fetched \(items.count) items" }

    // Nothing has run yet!
    Task {
        await program.run()   // "Fetched 3 items"
    }
}
// learnDeferredTaskPractical()

//: [Previous](@previous) | [Next](@next)
