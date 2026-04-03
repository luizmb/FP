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
    let task      = DeferredTask { 5 }
    let doubled   = task.fmap { $0 * 2 }                         // instance
    let doubled2  = DeferredTask<Int>.fmap { $0 * 2 }(task)      // static curried
    let withOp1   = { $0 * 2 } <£> task                          // fn left
    let withOp2   = task <&> { $0 * 2 }                          // value left
    let replaced  = task £> "done"                                // replace (container left)
    let replaced2 = "done" <£ task                                // replace (value left)

    await doubled.run()    // 10
    await doubled2.run()   // 10
    await withOp1.run()    // 10
    await withOp2.run()    // 10
    await replaced.run()   // "done"
    await replaced2.run()  // "done"
}
// learn(deferredTaskFunctor)

// MARK: - Applicative

func deferredTaskApplicative() async {
    let taskA = DeferredTask { 3 }
    let taskB = DeferredTask { 4 }

    // liftA2 — both run, results combined
    let sumTask = liftA2DeferredTask(+)(taskA, taskB)   // named free function

    // apply (named + operator)
    let fnTask: DeferredTask<@Sendable (Int) -> Int> = DeferredTask { { $0 * 10 } }
    let product1 = applyDeferredTask(fnTask, taskA)     // named
    let product2 = fnTask <*> taskA                     // operator

    // seqRight / seqLeft (named + operator)
    let seqR = taskA.seqRight(taskB)                    // named
    let seqL = taskA.seqLeft(taskB)                     // named

    await sumTask.run()    // 7
    await product1.run()   // 30
    await product2.run()   // 30
    await seqR.run()       // 4
    await (taskA *> taskB).run()   // 4  — operator
    await seqL.run()       // 3
    await (taskA <* taskB).run()   // 3  — operator
}
// learn(deferredTaskApplicative)

// MARK: - Monad

func deferredTaskMonad() async {
    let fetchId:   DeferredTask<Int>                     = DeferredTask { 42 }
    let fetchUser: @Sendable (Int) -> DeferredTask<String> = { id in DeferredTask { "User #\(id)" } }

    // flatMap — second task depends on first result
    let pipeline  = fetchId.flatMap(fetchUser)                      // instance
    let pipelined = DeferredTask<Int>.flatMap(fetchUser)(fetchId)   // static curried
    let piped     = fetchId >>- fetchUser                           // value left
    let pipedR    = fetchUser -<< fetchId                           // fn left

    // join — flatten nested DeferredTask
    let nested    = DeferredTask { DeferredTask { "hello" } }
    let flat      = DeferredTask<DeferredTask<String>>.join(nested)

    await pipeline.run()    // "User #42"
    await pipelined.run()   // "User #42"
    await piped.run()       // "User #42"
    await pipedR.run()      // "User #42"
    await flat.run()        // "hello"
}
// learn(deferredTaskMonad)

// MARK: - Kleisli

func deferredTaskKleisli() async {
    let countChars: @Sendable (String) -> DeferredTask<Int>    = { s in DeferredTask { s.count } }
    let describe:   @Sendable (Int) -> DeferredTask<String>    = { n in DeferredTask { "length: \(n)" } }
    let shout:      @Sendable (String) -> DeferredTask<String> = { s in DeferredTask { s.uppercased() } }

    // Named kleisli + operator
    let countThenDescribe   = DeferredTask<String>.kleisli(countChars, describe)   // named
    let countThenDescribeOp = countChars >=> describe                           // operator
    let fullPipeline        = countChars >=> describe >=> shout                 // chain

    await countThenDescribe("hello").run()    // "length: 5"
    await countThenDescribeOp("hello").run()  // "length: 5"
    await fullPipeline("hello").run()         // "LENGTH: 5"
}
// learn(deferredTaskKleisli)

// MARK: - Practical: lazy effect pipeline

func deferredTaskPractical() async {
    func authenticate(token: String) -> DeferredTask<Bool> {
        DeferredTask { token == "secret" }
    }
    @Sendable func fetchData() -> DeferredTask<[String]> {
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
