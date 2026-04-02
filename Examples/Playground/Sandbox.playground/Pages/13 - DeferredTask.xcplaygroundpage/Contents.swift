import FP

// ============================================================
// DEFERREDTASK<A>
//
// Lazy async computation — nothing runs until .run() is called.
// Descriptions of work, not running work. Like Haskell's IO.
// ============================================================

// MARK: - Construction & Running

func deferredTaskConstruction() async {
    let task = DeferredTask { 42 }
    // Nothing has executed yet. Only .run() triggers the closure.
    let result = await task.run()
    result   // 42
}
// learn(deferredTaskConstruction)

// MARK: - Functor

func deferredTaskFunctor() async {
    let task     = DeferredTask { 5 }
    let doubled  = task.fmap { $0 * 2 }   // still lazy
    let withOp1  = { $0 * 2 } <£> task
    let withOp2  = task <&> { $0 * 2 }
    let replaced = task £> "done"

    await doubled.run()    // 10
    await withOp1.run()    // 10
    await withOp2.run()    // 10
    await replaced.run()   // "done"
}
// learn(deferredTaskFunctor)

// MARK: - Applicative

func deferredTaskApplicative() async {
    let taskA = DeferredTask { 3 }
    let taskB = DeferredTask { 4 }

    // liftA2 — both run, results combined
    let sumTask = DeferredTask<Int>.liftA2(+)(taskA, taskB)

    // apply
    let fnTask  = DeferredTask<(Int) -> Int> { { $0 * 10 } }
    let product = fnTask <*> taskA

    await sumTask.run()    // 7
    await product.run()    // 30
}
// learn(deferredTaskApplicative)

// MARK: - Monad

func deferredTaskMonad() async {
    let fetchId   = DeferredTask { 42 }
    let fetchUser = { (id: Int) in DeferredTask { "User #\(id)" } }

    // flatMap — second task depends on first result
    let pipeline  = fetchId.flatMap(fetchUser)

    // bind + operator
    let piped     = fetchId >>- fetchUser

    // join — flatten nested DeferredTask
    let nested    = DeferredTask { DeferredTask { "hello" } }
    let flat      = DeferredTask<String>.join(nested)

    await pipeline.run()   // "User #42"
    await piped.run()      // "User #42"
    await flat.run()       // "hello"
}
// learn(deferredTaskMonad)

// MARK: - Kleisli

func deferredTaskKleisli() async {
    let countChars: @Sendable (String) -> DeferredTask<Int>    = { s in DeferredTask { s.count } }
    let describe:   @Sendable (Int) -> DeferredTask<String>    = { n in DeferredTask { "length: \(n)" } }
    let shout:      @Sendable (String) -> DeferredTask<String> = { s in DeferredTask { s.uppercased() } }

    let pipeline = countChars >=> describe >=> shout

    await pipeline("hello").run()   // "LENGTH: 5"
}
// learn(deferredTaskKleisli)

// MARK: - Practical: lazy effect pipeline

func deferredTaskPractical() async {
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
    await program.run()   // "Fetched 3 items"
}
// learn(deferredTaskPractical)

//: [Previous](@previous) | [Next](@next)
