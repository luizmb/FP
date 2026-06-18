import FP

// ============================================================
// WRITER<W: Monoid, A>
//
// Pairs a value with an accumulated log. flatMap appends logs
// transparently via Monoid.combine — you never merge manually.
// ============================================================

// MARK: - Construction & Extraction

func writerConstruction() {
    let w1 = Writer(42, ["computed answer"])
    let w2 = Writer("hello", "log entry; ")

    w1.runWriter() // (42, ["computed answer"])
    w1.evalWriter() // 42 — value only
    w1.execWriter() // ["computed answer"] — log only
    w2.runWriter() // ("hello", "log entry; ")
}

// learn(writerConstruction)

// MARK: - Functor

func writerFunctor() {
    let w = Writer(5, ["got 5"])

    let doubled = w.fmap { $0 * 2 }
    let withOp1 = { $0 * 2 } <£> w // fn left
    let withOp2 = w <&> { $0 * 2 } // value left
    let replaced = w £> "done" // replace (container left)
    let replacedF = "done" <£ w // replace (value left, flipped)

    doubled.runWriter() // (10, ["got 5"]) — log unchanged
    withOp1.runWriter() // (10, ["got 5"])
    withOp2.runWriter() // (10, ["got 5"])
    replaced.runWriter() // ("done", ["got 5"])
    replacedF.runWriter() // ("done", ["got 5"])
}

// learn(writerFunctor)

// MARK: - Applicative

func writerApplicative() {
    let wFn = Writer({ (x: Int) in x + 10 }, ["applied fn"])
    let wVal = Writer(5, ["got value"])

    // apply — combines logs
    let result1 = Writer<[String], Int>.apply(wFn, wVal)
    result1.runWriter() // (15, ["applied fn", "got value"])
    (wFn <*> wVal).runWriter() // (15, ["applied fn", "got value"])

    // liftA2
    let w1 = Writer(3, ["first"])
    let w2 = Writer(4, ["second"])
    Writer<[String], Int>.liftA2(+)(w1, w2).runWriter() // (7, ["first", "second"])

    // seqRight / seqLeft
    (w1 *> w2).runWriter() // (4, ["first", "second"])
    (w1 <* w2).runWriter() // (3, ["first", "second"])
}

// learn(writerApplicative)

// MARK: - Monad

func writerMonad() {
    // flatMap appends logs automatically via Monoid.combine
    let pipeline = Writer(5, ["start"])
        .flatMap { n in Writer(n + 1, ["added 1 → \(n + 1)"]) }
        .flatMap { n in Writer(n * 2, ["doubled → \(n * 2)"]) }
        .flatMap { n in Writer(n - 3, ["minus 3 → \(n - 3)"]) }

    pipeline.evalWriter() // 9  — ((5+1)*2)-3
    pipeline.execWriter()
    // ["start", "added 1 → 6", "doubled → 12", "minus 3 → 9"]

    // bind (curried static) + operators
    let step: (Int) -> Writer<[String], Int> = { n in Writer(n * 2, ["×2 → \(n * 2)"]) }
    Writer<[String], Int>.bind(step)(Writer(3, ["init"])).runWriter() // (6, ["init", "×2 → 6"])
    (Writer(3, ["init"]) >>- step).runWriter() // (6, ["init", "×2 → 6"])
    (step -<< Writer(3, ["init"])).runWriter() // (6, ["init", "×2 → 6"])

    // Kleisli
    let step1: (Int) -> Writer<[String], Int> = { n in Writer(n + 1, ["inc"]) }
    let step2: (Int) -> Writer<[String], Int> = { n in Writer(n * 3, ["×3"]) }
    let chain = Writer<[String], Int>.kleisli(step1, step2) // named
    let chainOp = step1 >=> step2 // operator
    let chainR = Writer<[String], Int>.kleisliBack(step2, step1) // named, right-to-left
    let chainROp = step2 <=< step1 // operator
    chain(4).runWriter() // (15, ["inc", "×3"])
    chainOp(4).runWriter() // (15, ["inc", "×3"])
    chainR(4).runWriter() // (15, ["inc", "×3"])
    chainROp(4).runWriter() // (15, ["inc", "×3"])
}

// learn(writerMonad)

// MARK: - Comonad

func writerComonad() {
    let w = Writer(5, ["got 5"])

    // extract :: Writer w a -> a
    w.extract // 5

    // extend :: (Writer w a -> b) -> Writer w a -> Writer w b
    // Applies f to the whole writer context, preserving the original log
    let doubled = w.extend { writer in writer.extract * 2 }
    doubled.runWriter() // (10, ["got 5"])

    // Named static form
    let tripled = Writer<[String], Int>.extend { writer in writer.extract * 3 }(w)
    tripled.runWriter() // (15, ["got 5"])

    // coflatMap — same as extend (value-first argument order)
    let described = w.coflatMap { writer in "value: \(writer.extract)" }
    described.runWriter() // ("value: 5", ["got 5"])

    // duplicate :: Writer w a -> Writer w (Writer w a)
    let dup = w.duplicate
    dup.runWriter() // (Writer(5, ["got 5"]), ["got 5"])
    dup.extract.runWriter() // (5, ["got 5"])

    // ->> operator (infixl 1) — w ->> f  =  extend f w
    let withOp = w ->> { writer in writer.extract + 10 }
    withOp.runWriter() // (15, ["got 5"])

    // <<- operator (infixr 1) — f <<- w  =  extend f w
    let withOpR = { (writer: Writer<[String], Int>) in writer.extract - 1 } <<- w
    withOpR.runWriter() // (4, ["got 5"])
}

// learn(writerComonad)

// MARK: - Practical: audit log

func writerAuditLog() {
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

    transaction.evalWriter() // 100.0
    transaction.execWriter()
    // ["[START] Balance: 100", "[OK] Withdrew 30.0", "[OK] Deposited 50.0", "[OK] Withdrew 20.0"]
}

// learn(writerAuditLog)

//: [Previous](@previous) | [Next](@next)
