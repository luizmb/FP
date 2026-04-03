import FP

// ============================================================
// DEFERREDSTREAM<Element>
//
// Lazy AsyncSequence — the factory isn't called until the first
// iteration. Streaming counterpart to DeferredTask.
// ============================================================

// MARK: - Construction

func deferredStreamConstruction() async {
    // Factory stored, not invoked yet
    let stream = DeferredStream {
        AsyncStream<Int> { continuation in
            for i in 1...5 { continuation.yield(i) }
            continuation.finish()
        }
    }

    var collected: [Int] = []
    for await value in stream { collected.append(value) }
    collected   // [1, 2, 3, 4, 5]
}
// learn(deferredStreamConstruction)

// MARK: - Functor

func deferredStreamFunctor() async {
    let stream = DeferredStream {
        AsyncStream<Int> { c in
            for i in 1...3 { c.yield(i) }
            c.finish()
        }
    }

    let doubled   = stream.fmap { $0 * 2 }                              // instance
    let doubled2  = DeferredStream<Int>.fmap { $0 * 2 }(stream)         // static curried
    let withOp1   = { $0 * 2 } <£> stream                               // fn left
    let withOp2   = stream <&> { $0 * 2 }                               // value left
    let replaced  = stream £> "x"                                       // replace (container left)
    let replaced2 = "x" <£ stream                                       // replace (value left)

    var r1: [Int] = [], r2: [Int] = [], r3: [Int] = [], r4: [Int] = []
    var r5: [String] = [], r6: [String] = []
    for await v in doubled   { r1.append(v) }
    for await v in doubled2  { r2.append(v) }
    for await v in withOp1   { r3.append(v) }
    for await v in withOp2   { r4.append(v) }
    for await v in replaced  { r5.append(v) }
    for await v in replaced2 { r6.append(v) }
    r1   // [2, 4, 6]
    r2   // [2, 4, 6]
    r3   // [2, 4, 6]
    r4   // [2, 4, 6]
    r5   // ["x", "x", "x"]
    r6   // ["x", "x", "x"]
}
// learn(deferredStreamFunctor)

// MARK: - Monad

func deferredStreamMonad() async {
    let stream = DeferredStream {
        AsyncStream<Int> { c in
            for i in 1...3 { c.yield(i) }
            c.finish()
        }
    }

    // flatMap — each element expands into a sub-stream, results flattened
    let expand: @Sendable (Int) -> DeferredStream<Int> = { n in
        DeferredStream { AsyncStream { c in c.yield(n); c.yield(n * 10); c.finish() } }
    }
    let expanded  = stream.flatMap(expand)                    // instance
    let expanded2 = DeferredStream<Int>.flatMap(expand)(stream)   // static curried
    _ = stream >>- expand                                     // value left
    _ = expand -<< stream                                     // fn left

    var r1: [Int] = [], r2: [Int] = []
    for await v in expanded  { r1.append(v) }
    for await v in expanded2 { r2.append(v) }
    r1   // [1, 10, 2, 20, 3, 30]
    r2   // [1, 10, 2, 20, 3, 30]
}
// learn(deferredStreamMonad)

// MARK: - Kleisli

func deferredStreamKleisli() async {
    let countStr:  @Sendable (Int) -> DeferredStream<String> = { n in
        DeferredStream { AsyncStream { c in c.yield("n:\(n)"); c.finish() } }
    }
    let shout: @Sendable (String) -> DeferredStream<String> = { s in
        DeferredStream { AsyncStream { c in c.yield(s.uppercased()); c.finish() } }
    }

    let pipeline   = DeferredStream<Int>.kleisli(countStr, shout)   // named
    let pipelineOp = countStr >=> shout                                 // operator
    let pipelineR  = shout <=< countStr                                 // right-to-left operator

    var r1: [String] = [], r2: [String] = [], r3: [String] = []
    for await v in pipeline(5)   { r1.append(v) }
    for await v in pipelineOp(5) { r2.append(v) }
    for await v in pipelineR(5)  { r3.append(v) }
    r1   // ["N:5"]
    r2   // ["N:5"]
    r3   // ["N:5"]
}
// learn(deferredStreamKleisli)

// MARK: - Applicative

func deferredStreamApplicative() async {
    let streamA = DeferredStream { AsyncStream<Int> { c in c.yield(1); c.yield(2); c.finish() } }
    let streamB = DeferredStream { AsyncStream<Int> { c in c.yield(10); c.yield(20); c.finish() } }

    // liftA2 — zip-based, pairs elements positionally
    let sumStream = liftA2DeferredStream(+)(streamA, streamB)

    // apply (named + operator)
    let fnStream = DeferredStream<@Sendable (Int) -> Int> {
        AsyncStream { c in c.yield { $0 * 3 }; c.finish() }
    }
    let applied    = applyDeferredStream(fnStream, streamA)   // named
    let appliedOp  = fnStream <*> streamA                     // operator

    // seqRight / seqLeft (named + operator)
    let seqR   = streamA.seqRight(streamB)   // named
    let seqROp = streamA *> streamB          // operator
    let seqL   = streamA.seqLeft(streamB)    // named
    let seqLOp = streamA <* streamB          // operator

    var r1: [Int] = [], r2: [Int] = [], r3: [Int] = []
    var r4: [Int] = [], r5: [Int] = [], r6: [Int] = [], r7: [Int] = []
    for await v in sumStream   { r1.append(v) }
    for await v in applied     { r2.append(v) }
    for await v in appliedOp   { r3.append(v) }
    for await v in seqR        { r4.append(v) }
    for await v in seqROp      { r5.append(v) }
    for await v in seqL        { r6.append(v) }
    for await v in seqLOp      { r7.append(v) }
    r1   // [11, 22]
    r2   // [3, 6]
    r3   // [3, 6]
    r4   // [10, 20]
    r5   // [10, 20]
    r6   // [1, 2]
    r7   // [1, 2]
}
// learn(deferredStreamApplicative)

// MARK: - Practical: alert stream

func deferredStreamPractical() async {
    let prices = DeferredStream {
        AsyncStream<Double> { c in
            for price in [1.0, 1.2, 0.9, 1.5, 1.1] { c.yield(price) }
            c.finish()
        }
    }

    // Filter via flatMap — emit only when price exceeds threshold
    let alerts = prices.flatMap { price -> DeferredStream<String> in
        price > 1.3
            ? DeferredStream { AsyncStream { c in c.yield("ALERT: \(price)"); c.finish() } }
            : DeferredStream { AsyncStream { c in c.finish() } }
    }

    for await alert in alerts {
        alert   // "ALERT: 1.5"
    }
}
// learn(deferredStreamPractical)

//: [Previous](@previous) | [Next](@next)
