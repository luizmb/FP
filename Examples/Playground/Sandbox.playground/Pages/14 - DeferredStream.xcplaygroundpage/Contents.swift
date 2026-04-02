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

    let doubled  = stream.fmap { $0 * 2 }
    let withOp   = { $0 * 2 } <£> stream
    let replaced = stream £> "x"

    var r1: [Int] = [], r2: [Int] = [], r3: [String] = []
    for await v in doubled  { r1.append(v) }
    for await v in withOp   { r2.append(v) }
    for await v in replaced { r3.append(v) }
    r1   // [2, 4, 6]
    r2   // [2, 4, 6]
    r3   // ["x", "x", "x"]
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
    let expanded = stream.flatMap { n in
        DeferredStream {
            AsyncStream<Int> { c in
                c.yield(n)
                c.yield(n * 10)
                c.finish()
            }
        }
    }

    var result: [Int] = []
    for await v in expanded { result.append(v) }
    result   // [1, 10, 2, 20, 3, 30]
}
// learn(deferredStreamMonad)

// MARK: - Applicative

func deferredStreamApplicative() async {
    let streamA = DeferredStream { AsyncStream<Int> { c in c.yield(1); c.yield(2); c.finish() } }
    let streamB = DeferredStream { AsyncStream<Int> { c in c.yield(10); c.yield(20); c.finish() } }

    let sumStream = DeferredStream<Int>.liftA2(+)(streamA, streamB)

    var result: [Int] = []
    for await v in sumStream { result.append(v) }
    result   // [11, 22]
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
