import FP

// ============================================================
// FUNCTION UTILITIES
//
// Building blocks for tacit/point-free programming.
//   id, const, ignore     — trivial combinators
//   curry / uncurry       — arity transforms
//   flip / partialApply   — argument reordering / partial application
//   lazy / unlazy         — zero-argument wrapping
//   compose / apply       — function composition and application
//   Endo<A>               — endomorphism monoid under composition
// ============================================================

// MARK: - id

func id() {
    id(42) // 42
    id("hello") // "hello"

    // Useful as a no-op transform in map/flatMap chains
    let values: [Int] = [1, 2, 3]
    values.map(id) // [1, 2, 3]

    // £ (apply) with id is the same as calling directly
    id £ 100 // 100
}

// learn(id)

// MARK: - const

func const() {
    // const(x) returns a function that ignores its argument and returns x
    let alwaysFive: (String) -> Int = const(5)
    alwaysFive("anything") // 5
    alwaysFive("") // 5

    // Useful to replace lambdas like `{ _ in value }`
    let words = ["apple", "banana", "cherry"]
    words.map(const("x")) // ["x", "x", "x"]

    // Compare with £> operator which does the same thing inline
    words <&> const("x") // ["x", "x", "x"]
}

// learn(const)

// MARK: - ignore

func ignore() {
    // ignore discards all its arguments and returns Void
    ignore(1, 2, 3) // ()

    // Useful when a closure must return Void but you have a value
    let task: () -> Void = { ignore(42) }
    task()

    // Of<T>.ignore() gives you a typed (T) -> Void function
    let discard = Of<Int>.ignore()
    type(of: discard) // (Int) -> ()
    discard(99)
}

// learn(ignore)

// MARK: - curry / uncurry

func curryUncurry() {
    // curry — (A, B) -> C   becomes   (A) -> (B) -> C
    let add: (Int, Int) -> Int = { $0 + $1 }
    let curriedAdd = curry(add) // (Int) -> (Int) -> Int

    curriedAdd(3)(4) // 7

    let add3 = curriedAdd(3) // (Int) -> Int — partially applied
    [1, 2, 3].map(add3) // [4, 5, 6]

    // uncurry — inverse: (A) -> (B) -> C   becomes   (A, B) -> C
    let uncurriedAdd = uncurry(curriedAdd)
    uncurriedAdd(3, 4) // 7
}

// learn(curryUncurry)

// MARK: - flip / partialApply

func flipPartialApply() {
    // flip — swaps argument order (curried form)
    let subtract: (Int, Int) -> Int = { $0 - $1 }
    let flipped = flip(subtract) // (Int) -> (Int) -> Int  (b first)

    subtract(10, 3) // 7
    flipped(3)(10) // 7 — same result, reversed call order

    // partialApply — curry + immediately apply the first argument
    let multiplyBy: (Int, Int) -> Int = { $0 * $1 }
    let triple = partialApply(multiplyBy, 3) // (Int) -> Int
    [1, 2, 3, 4].map(triple) // [3, 6, 9, 12]

    // partialApplyFlip — partially apply the SECOND argument
    let addTo10 = partialApplyFlip({ (a: Int, b: Int) in a + b }, 10)
    [1, 2, 3].map(addTo10) // [11, 12, 13]
}

// learn(flipPartialApply)

// MARK: - lazy / unlazy

func lazyUnlazy() {
    // lazy — wraps a value in () -> A   (adds a layer of deferred evaluation)
    let lazyInt = lazy(42) // () -> Int
    lazyInt() // 42

    // lazy — wraps a function in () -> (A) -> B
    let lazyDouble = lazy { (n: Int) in n * 2 } // () -> (Int) -> Int
    lazyDouble()(5) // 10

    // unlazy — removes the () layer (evaluates immediately)
    let eager = unlazy(lazyInt) // Int = 42
    eager // 42

    // unlazy on () -> (A) -> B gives (A) -> B
    let doubled = unlazy(lazyDouble) // (Int) -> Int
    [1, 2, 3].map(doubled) // [2, 4, 6]
}

// learn(lazyUnlazy)

// MARK: - compose / apply

func composeApply() {
    let addOne: (Int) -> Int = { $0 + 1 }
    let double: (Int) -> Int = { $0 * 2 }
    let toStr: (Int) -> String = { "result: \($0)" }

    // compose — left-to-right function composition (named function)
    let pipeline = compose(addOne, compose(double, toStr)) // (Int) -> String
    pipeline(4) // "result: 10"

    // >>> operator — left-to-right, more readable
    let pipeline2 = addOne >>> double >>> toStr
    pipeline2(4) // "result: 10"

    // <<< operator — right-to-left (mathematical / Haskell order)
    let pipeline3 = toStr <<< double <<< addOne
    pipeline3(4) // "result: 10"

    // apply — call a function with a value (named form)
    apply(4, pipeline2) // "result: 10"

    // £ operator — function-left application  (fn £ value)
    pipeline2 £ 4 // "result: 10"

    // |> operator — value-left application  (value |> fn)
    4 |> pipeline2 // "result: 10"

    // Point-free map using >>>
    [1, 2, 3].map(addOne >>> double) // [4, 6, 8]
}

// learn(composeApply)

// MARK: - compose3 / compose4

func composeN() {
    // compose3 / compose4 — compose 3 or 4 functions without nesting
    let step1: (Int) -> Int = { $0 + 1 }
    let step2: (Int) -> Double = { Double($0) }
    let step3: (Double) -> String = { String(format: "%.1f", $0) }

    let three = compose3(step1, step2, step3)
    three(9) // "10.0"
}

// learn(composeN)

// MARK: - Endo<A>

func endo() {
    // Endo wraps an endomorphism: (A) -> A
    let trim = Endo<String> { $0.trimmingCharacters(in: .whitespaces) }
    let lower = Endo<String> { $0.lowercased() }
    let exclaim = Endo<String> { $0 + "!" }

    // Run directly (callAsFunction support)
    trim.runEndo("  Hello  ") // "Hello"
    trim("  Hello  ") // "Hello" — callAsFunction

    // Semigroup: combine via <> (left-to-right composition)
    let trimLower = trim <> lower
    trimLower("  HELLO  ") // "hello"

    // Monoid identity — do-nothing transformation
    Endo<String>.identity.runEndo("unchanged") // "unchanged"

    // mconcat — collapse a list of Endos into one pipeline
    let normalize = mconcat([trim, lower, exclaim])
    normalize.runEndo("  HELLO  ") // "hello!"
    normalize("  HELLO  ") // "hello!" — callAsFunction

    // Free constructor
    let shout = endo { (s: String) in s.uppercased() }
    let shoutAndExclaim = shout <> exclaim
    shoutAndExclaim("hello") // "HELLO!"
}

// learn(endo)

// MARK: - Numeric Utilities

func numericUtilities() {
    // symmetricRange — named form: produces ClosedRange from center ± delta
    symmetricRange(5, delta: 2) // 3...7
    symmetricRange(10.0, delta: 0.5) // 9.5...10.5

    // ± operator (ASCII alias: +/-)
    5 ± 2 // 3...7
    10.0 ± 0.5 // 9.5...10.5
    5 +/- 2 // 3...7

    // rangeMatch — named form: value ~= range (flipped)
    rangeMatch(5, in: 3...7) // true
    rangeMatch(10, in: 3...7) // false

    // ≅ operator — flipped pattern match: value ≅ range
    5 ≅ 3...7 // true
    10 ≅ 3...7 // false
    5 ≅ 5 ± 2 // true
    200 ≅ 200...299 // true — HTTP success range
    404 ≅ 200...299 // false

    // power — named form for floating-point exponentiation
    power(2.0, 10) // 1024.0
    power(3.0, 3) // 27.0

    // ^ operator (BinaryFloatingPoint only — Int uses power())
    2.0 ^ 10 // 1024.0
    3.0 ^ 3 // 27.0
    5.0 ^ 0 // 1.0
}

// learn(numericUtilities)

// MARK: - Point-free pipeline (putting it all together)

struct Person { let name: String; let score: Int }

func tacitProgramming() {
    let people = [
        Person(name: "  alice ", score: 42),
        Person(name: "BOB", score: 7),
        Person(name: " Carol", score: 100)
    ]

    // Normalise names tacit using >>>
    let trim: (String) -> String = { $0.trimmingCharacters(in: .whitespaces) }
    let lower: (String) -> String = { $0.lowercased() }
    let normaliseName = trim >>> lower

    people.map(\.name).map(normaliseName) // ["alice", "bob", "carol"]

    // Partial application for filtering (score >= threshold)
    let highScorer = 42 |> ((\Person.score >>> curry(>=)) |> flip)
    people.filter(highScorer).map(\.name >>> normaliseName) // ["alice", "carol"]

    // Endo pipeline for string normalisation
    let sanitise: Endo<String> = mconcat([
        trim |> endo,
        lower |> endo
    ])
    people.map(\.name).map(sanitise.runEndo) // ["alice", "bob", "carol"]
}

learn(tacitProgramming)

//: [Previous](@previous)
