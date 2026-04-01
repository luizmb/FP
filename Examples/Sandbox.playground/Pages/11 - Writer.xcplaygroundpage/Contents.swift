import FP

// ============================================================
// WRITER<W: Monoid, A>
// runWriter  :: Writer<W, A> -> (A, W)
// evalWriter :: Writer<W, A> -> A
// execWriter :: Writer<W, A> -> W
//
// Writer pairs a value with an accumulated log. The log W must
// be a Monoid so that logs from sequential computations can be
// combined automatically during flatMap.
//
// The defining feature: flatMap (>>=) appends logs transparently.
// You never manage the log manually — just emit locally and the
// Monoid handles merging.
//
// Common choices for W: [String] (log lines), String, [Event], Int (counts)
// ============================================================

// MARK: - Construction & Extraction

// let w1 = Writer(42, ["computed answer"])                   // Writer<[String], Int>
// let w2 = Writer("hello", "log entry; ")                    // Writer<String, String>

// --- Extract ---
// w1.runWriter()                           // (42, ["computed answer"])
// w1.evalWriter()                          // 42 — value only
// w1.execWriter()                          // ["computed answer"] — log only


// MARK: - Functor (maps value, preserves log)

// let w = Writer(5, ["got 5"])

// --- Named function ---
// w.fmap { $0 * 2 }                        // Writer(10, ["got 5"]) — log unchanged

// --- Operators ---
// { $0 * 2 } <£> w                         // Writer(10, ["got 5"])
// w <&> { $0 * 2 }                         // Writer(10, ["got 5"])
// w £> "done"                              // Writer("done", ["got 5"])


// MARK: - Applicative

// let wFn = Writer({ (x: Int) in x + 10 }, ["applied fn"])
// let wVal = Writer(5, ["got value"])

// --- apply: combines logs via Monoid ---
// Writer<[String], Int>.apply(wFn, wVal)   // Writer(15, ["applied fn", "got value"])
// wFn <*> wVal                             // Writer(15, ["applied fn", "got value"])

// --- liftA2 ---
// let w1 = Writer(3, ["first"])
// let w2 = Writer(4, ["second"])
// Writer<[String], Int>.liftA2(+)(w1, w2) // Writer(7, ["first", "second"])

// --- seqRight / seqLeft ---
// w1 *> w2                                 // Writer(4, ["first", "second"])
// w1 <* w2                                 // Writer(3, ["first", "second"])


// MARK: - Monad (flatMap appends logs via Monoid.combine)

// --- Each step emits its own log; they accumulate automatically ---
// let pipeline = Writer(5, ["start: 5"])
//     .flatMap { n in Writer(n + 1, ["added 1: \(n + 1)"]) }
//     .flatMap { n in Writer(n * 2, ["doubled: \(n * 2)"]) }
//     .flatMap { n in Writer(n - 3, ["subtracted 3: \(n - 3)"]) }

// pipeline.evalWriter()                    // 9   — ((5+1)*2)-3
// pipeline.execWriter()                    // ["start: 5", "added 1: 6", "doubled: 12", "subtracted 3: 9"]

// --- bind (curried) ---
// let step: (Int) -> Writer<[String], Int> = { n in Writer(n * 2, ["doubled \(n) to \(n*2)"]) }
// Writer<[String], Int>.bind(step)(Writer(5, ["initial"]))
// // Writer(10, ["initial", "doubled 5 to 10"])

// --- Operator ---
// Writer(5, ["initial"]) >>- step          // Writer(10, ["initial", "doubled 5 to 10"])

// --- Kleisli ---
// let step1: (Int) -> Writer<[String], Int> = { n in Writer(n + 1, ["increment"]) }
// let step2: (Int) -> Writer<[String], Int> = { n in Writer(n * 3, ["triple"]) }
// let composed = step1 >=> step2
// composed(4).runWriter()                  // (15, ["increment", "triple"]) — (4+1)*3 = 15


// MARK: - Practical: audit logging

// struct Money: CustomStringConvertible {
//     let amount: Double
//     var description: String { "$\(amount)" }
// }

// func withdraw(_ amount: Double, from balance: Double) -> Writer<[String], Double> {
//     guard balance >= amount else {
//         return Writer(balance, ["[ERROR] Insufficient funds: tried \(amount), have \(balance)"])
//     }
//     return Writer(balance - amount, ["[OK] Withdrew \(amount), balance: \(balance - amount)"])
// }

// func deposit(_ amount: Double) -> (Double) -> Writer<[String], Double> {
//     { balance in Writer(balance + amount, ["[OK] Deposited \(amount), balance: \(balance + amount)"]) }
// }

// let transaction = Writer(100.0, ["[START] Balance: 100"])
//     >>- withdraw(30)
//     >>- deposit(50)
//     >>- withdraw(20)

// transaction.evalWriter()                 // 100.0
// transaction.execWriter()
// // ["[START] Balance: 100",
// //  "[OK] Withdrew 30.0, balance: 70.0",
// //  "[OK] Deposited 50.0, balance: 120.0",
// //  "[OK] Withdrew 20.0, balance: 100.0"]

//: [Previous](@previous) | [Next](@next)
