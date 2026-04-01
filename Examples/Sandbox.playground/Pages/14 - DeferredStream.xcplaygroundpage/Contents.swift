import FP
import PlaygroundSupport

// ============================================================
// DEFERREDSTREAM<Element>
//
// DeferredStream is the streaming counterpart to DeferredTask.
// It wraps a lazy AsyncStream factory: the factory is not called
// until the first iteration begins. This makes it composable and
// safe to pass around without triggering side effects.
//
// Conforms to AsyncSequence — use it in `for await` loops.
//
// Functor, Applicative, and Monad instances allow you to transform
// and compose streams before any element is produced.
// ============================================================

// ---- Uncomment the block below to enable async execution ----
// PlaygroundPage.current.needsIndefiniteExecution = true


// MARK: - Construction

// --- From an AsyncStream factory (lazy — factory not called yet) ---
// let stream = DeferredStream {
//     AsyncStream<Int> { continuation in
//         for i in 1...5 {
//             continuation.yield(i)
//         }
//         continuation.finish()
//     }
// }
// // Nothing runs. The factory is stored, not invoked.

// --- Iterate (triggers the factory) ---
// Task {
//     for await value in stream {
//         print(value)                     // 1, 2, 3, 4, 5
//     }
//     PlaygroundPage.current.finishExecution()
// }


// MARK: - Functor (transform each element, still lazy)

// let stream = DeferredStream {
//     AsyncStream<Int> { continuation in
//         for i in 1...3 { continuation.yield(i) }
//         continuation.finish()
//     }
// }

// --- Named function ---
// let doubled = stream.fmap { $0 * 2 }    // DeferredStream<Int> — still lazy

// --- Operators ---
// let doubled2 = { $0 * 2 } <£> stream    // same
// let doubled3 = stream <&> { $0 * 2 }    // same

// Task {
//     for await value in doubled {
//         print(value)                     // 2, 4, 6
//     }
//     PlaygroundPage.current.finishExecution()
// }

// --- replace all elements with a constant ---
// let constant = stream £> "hello"
// Task {
//     for await value in constant {
//         print(value)                     // "hello", "hello", "hello"
//     }
//     PlaygroundPage.current.finishExecution()
// }


// MARK: - Monad (flatMap each element into a new stream, then flatten)

// let stream = DeferredStream {
//     AsyncStream<Int> { continuation in
//         for i in 1...3 { continuation.yield(i) }
//         continuation.finish()
//     }
// }

// --- flatMap: each element expands into a sub-stream ---
// let expanded = stream.flatMap { n in
//     DeferredStream {
//         AsyncStream<Int> { continuation in
//             continuation.yield(n)
//             continuation.yield(n * 10)
//             continuation.finish()
//         }
//     }
// }

// Task {
//     for await value in expanded {
//         print(value)                     // 1, 10, 2, 20, 3, 30
//     }
//     PlaygroundPage.current.finishExecution()
// }

// --- bind (curried) ---
// let expand: (Int) -> DeferredStream<Int> = { n in
//     DeferredStream { AsyncStream { c in c.yield(n); c.yield(-n); c.finish() } }
// }
// let bound = DeferredStream<Int>.bind(expand)(stream)
// // Task { for await v in bound { print(v) } ... }  // 1, -1, 2, -2, 3, -3


// MARK: - Applicative

// let streamA = DeferredStream {
//     AsyncStream<Int> { c in c.yield(1); c.yield(2); c.finish() }
// }
// let streamB = DeferredStream {
//     AsyncStream<Int> { c in c.yield(10); c.yield(20); c.finish() }
// }

// --- liftA2 ---
// let sumStream = DeferredStream<Int>.liftA2(+)(streamA, streamB)


// MARK: - Practical: live data pipeline

// --- Simulated ticker that emits prices ---
// let prices = DeferredStream {
//     AsyncStream<Double> { continuation in
//         for price in [1.0, 1.2, 0.9, 1.5, 1.1] {
//             continuation.yield(price)
//         }
//         continuation.finish()
//     }
// }

// --- Transform: only keep prices above threshold, format as string ---
// let alerts = prices
//     <&> { price in (price, price > 1.3) }
//     >>- { pair in
//         pair.1
//             ? DeferredStream { AsyncStream { c in c.yield("ALERT: \(pair.0)"); c.finish() } }
//             : DeferredStream { AsyncStream { c in c.finish() } }
//     }

// Task {
//     for await alert in alerts {
//         print(alert)                     // "ALERT: 1.5"
//     }
//     PlaygroundPage.current.finishExecution()
// }

//: [Previous](@previous) | [Next](@next)
