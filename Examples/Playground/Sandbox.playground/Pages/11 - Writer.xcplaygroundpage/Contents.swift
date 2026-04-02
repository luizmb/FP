import FP

// ============================================================
// WRITER<W: Monoid, A>
//
// Pairs a value with an accumulated log. flatMap appends logs
// transparently via Monoid.combine — you never merge manually.
// ============================================================

// MARK: - Construction & Extraction

func learnWriterConstruction() {
    let w1 = Writer(42, ["computed answer"])
    let w2 = Writer("hello", "log entry; ")

    w1.runWriter()    // (42, ["computed answer"])
    w1.evalWriter()   // 42 — value only
    w1.execWriter()   // ["computed answer"] — log only
    w2.runWriter()    // ("hello", "log entry; ")
}
// learnWriterConstruction()

// MARK: - Functor

func learnWriterFunctor() {
    let w = Writer(5, ["got 5"])

    let doubled  = w.fmap { $0 * 2 }
    let withOp   = { $0 * 2 } <£> w
    let replaced = w £> "done"

    doubled.runWriter()    // (10, ["got 5"]) — log unchanged
    withOp.runWriter()     // (10, ["got 5"])
    replaced.runWriter()   // ("done", ["got 5"])
}
// learnWriterFunctor()

// MARK: - Applicative

func learnWriterApplicative() {
    let wFn  = Writer({ (x: Int) in x + 10 }, ["applied fn"])
    let wVal = Writer(5, ["got value"])

    // apply — combines logs
    let result1 = Writer<[String], Int>.apply(wFn, wVal)
    result1.runWriter()                                        // (15, ["applied fn", "got value"])
    (wFn <*> wVal).runWriter()                                 // (15, ["applied fn", "got value"])

    // liftA2
    let w1 = Writer(3, ["first"])
    let w2 = Writer(4, ["second"])
    Writer<[String], Int>.liftA2(+)(w1, w2).runWriter()   // (7, ["first", "second"])

    // seqRight / seqLeft
    (w1 *> w2).runWriter()                                     // (4, ["first", "second"])
    (w1 <* w2).runWriter()                                     // (3, ["first", "second"])
}
// learnWriterApplicative()

// MARK: - Monad

func learnWriterMonad() {
    // flatMap appends logs automatically via Monoid.combine
    let pipeline = Writer(5, ["start"])
        .flatMap { n in Writer(n + 1, ["added 1 → \(n + 1)"]) }
        .flatMap { n in Writer(n * 2, ["doubled → \(n * 2)"]) }
        .flatMap { n in Writer(n - 3, ["minus 3 → \(n - 3)"]) }

    pipeline.evalWriter()   // 9  — ((5+1)*2)-3
    pipeline.execWriter()
    // ["start", "added 1 → 6", "doubled → 12", "minus 3 → 9"]

    // bind (curried) + operator
    let step: (Int) -> Writer<[String], Int> = { n in Writer(n * 2, ["×2 → \(n * 2)"]) }
    (Writer(3, ["init"]) >>- step).runWriter()   // (6, ["init", "×2 → 6"])

    // Kleisli
    let step1: (Int) -> Writer<[String], Int> = { n in Writer(n + 1, ["inc"]) }
    let step2: (Int) -> Writer<[String], Int> = { n in Writer(n * 3, ["×3"]) }
    (step1 >=> step2)(4).runWriter()             // (15, ["inc", "×3"])
}
// learnWriterMonad()

// MARK: - Practical: audit log

func learnWriterAuditLog() {
    func withdraw(_ amount: Double) -> (Double) -> Writer<[String], Double> {
        { balance in
            guard balance >= amount else {
                return Writer(balance, ["[ERR] Insufficient: need \(amount), have \(balance)"])
            }
            return Writer(balance - amount, ["[OK] Withdrew \(amount)"])
        }
    }
    func deposit(_ amount: Double) -> (Double) -> Writer<[String], Double> {
        { balance in Writer(balance + amount, ["[OK] Deposited \(amount)"]) }
    }

    let transaction = Writer(100.0, ["[START] Balance: 100"])
        >>- withdraw(30)
        >>- deposit(50)
        >>- withdraw(20)

    transaction.evalWriter()   // 100.0
    transaction.execWriter()
    // ["[START] Balance: 100", "[OK] Withdrew 30.0", "[OK] Deposited 50.0", "[OK] Withdrew 20.0"]
}
// learnWriterAuditLog()

//: [Previous](@previous) | [Next](@next)
