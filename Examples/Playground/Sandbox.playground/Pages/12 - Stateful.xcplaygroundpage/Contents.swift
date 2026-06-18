import FP

// ============================================================
// STATEFUL<S, A>
//
// Threads mutable state through a sequence of computations
// without passing it explicitly. flatMap wires state in/out.
// Named "Stateful" (not State) to avoid SwiftUI conflicts.
// ============================================================

// MARK: - Construction & Running

func statefulConstruction() {
    let readState = Stateful<Int, Int> { s in s }
    let increment = Stateful<Int, Void> { s in s += 1 }
    let double = Stateful<Int, Void> { s in s *= 2 }

    increment.eval(5) // () — the Void result
    increment.exec(5) // 6  — the new state
    increment.runStateful(5) // ((), 6) — both

    readState.runStateful(42) // (42, 42)
    double.runStateful(3) // ((), 6)
}

// learn(statefulConstruction)

// MARK: - get / put / modify patterns

func statefulGetPutModify() {
    let getState = Stateful<Int, Int> { s in s }
    let putState = { (n: Int) in Stateful<Int, Void> { s in s = n } }
    let modifyState = { (f: @escaping (Int) -> Int) in Stateful<Int, Void> { s in s = f(s) } }

    getState.runStateful(42) // (42, 42)
    putState(100).runStateful(42) // ((), 100)
    modifyState { $0 * 2 }.runStateful(5) // ((), 10)
}

// learn(statefulGetPutModify)

// MARK: - Functor

func statefulFunctor() {
    let s = Stateful<Int, Int> { state in state * 2 }

    // Named forms
    let asString = s.fmap { "value: \($0)" } // instance
    let asString2 = Stateful<Int, Int>.fmap { "v:\($0)" }(s) // static curried
    asString.eval(5) // "value: 10"
    asString2.eval(3) // "v:6"

    // Operators
    _ = { "v:\($0)" } <£> s // fn left
    (s <&> { "v:\($0)" }).eval(3) // "v:6" — value left
    (s £> "done").eval(5) // "done" — replace
    ("done" <£ s).eval(5) // "done" — flipped
}

// learn(statefulFunctor)

// MARK: - Applicative

func statefulApplicative() {
    let sx = Stateful<Int, Int> { s in s } // read state
    let sy = Stateful<Int, Int> { s in s * 2 } // read state × 2

    // liftA2 — threads state left-to-right through both
    let sum = Stateful<Int, Int>.liftA2(+)(sx, sy)
    sum.runStateful(3) // (9, 3) — 3 + 6

    // apply
    let sf = Stateful<Int, (Int) -> Int> { s in
        let s = s
        return { $0 + s }
    }
    Stateful<Int, Int>.apply(sf, sx).runStateful(5) // (10, 5) — 5 + 5
    (sf <*> sx).runStateful(5) // (10, 5)

    // seqRight / seqLeft
    let inc = Stateful<Int, Void> { s in s += 1 }
    sx.seqRight(sy).runStateful(2) // (4, 2) — keeps sy result
    (inc *> sx).runStateful(0) // (1, 1) — inc then read
    sx.seqLeft(sy).runStateful(2) // (2, 2) — keeps sx result
    (sx <* inc).runStateful(0) // (0, 1) — read then inc, keep read
}

// learn(statefulApplicative)

// MARK: - Monad

func statefulMonad() {
    let getState = Stateful<Int, Int> { s in s }
    let increment = Stateful<Int, Void> { s in s += 1 }

    // flatMap — threads state automatically
    let readAfterInc = increment.flatMap { _ in getState }
    readAfterInc.runStateful(0) // (1, 1)

    // Three increments then read
    let thrice = increment
        .flatMap { _ in increment }
        .flatMap { _ in increment }
        .flatMap { _ in getState }
    thrice.runStateful(0) // (3, 3)

    // bind (curried static) + operators
    let step: (Int) -> Stateful<Int, String> = { n in Stateful { s in s = n * 2; return "set \(n*2)" } }
    Stateful<Int, Int>.bind(step)(getState).runStateful(5) // ("set 10", 10) — named
    (getState >>- step).runStateful(5) // ("set 10", 10) — value left
    (step -<< getState).runStateful(5) // ("set 10", 10) — fn left

    // join — outer type must wrap the inner Stateful
    let nested = Stateful<Int, Stateful<Int, Int>> { _ in getState }
    Stateful<Int, Stateful<Int, Int>>.join(nested).runStateful(3) // (3, 3)

    // Kleisli
    let addN: (Int) -> Stateful<Int, Void> = { n in Stateful { s in s += n } }
    let readState: (()) -> Stateful<Int, Int> = { _ in getState }
    let read3 = Stateful<Int, Void>.kleisli(addN, readState) // named
    let read3Op = addN >=> readState // operator
    let read3R = Stateful<Int, Void>.kleisliBack(readState, addN) // named, right-to-left
    let read3ROp = readState <=< addN // operator
    read3(3).runStateful(0) // (3, 3)
    read3Op(3).runStateful(0) // (3, 3)
    read3R(3).runStateful(0) // (3, 3)
    read3ROp(3).runStateful(0) // (3, 3)
}

// learn(statefulMonad)

// MARK: - Practical: stack machine

func statefulStack() {
    typealias Stack = [Int]

    let push: (Int) -> Stateful<Stack, Void> = { n in Stateful { stack in stack.append(n) } }
    let pop = Stateful<Stack, Int?> { stack in stack.isEmpty ? nil : stack.removeLast() }
    let peek = Stateful<Stack, Int?> { stack in stack.last }

    let program = push(1)
        .flatMap { _ in push(2) }
        .flatMap { _ in push(3) }
        .flatMap { _ in pop }
        .flatMap { popped in push((popped ?? 0) * 10) }

    program.exec([]) // [1, 2, 30]

    let readTop = peek
    readTop.eval([10, 20, 30]) // Optional(30)
}

// learn(statefulStack)

// MARK: - Practical: unique ID generator

func statefulIdGenerator() {
    let nextId = Stateful<Int, Int> { counter in
        let id = counter
        counter += 1
        return id
    }

    let allocateThree = nextId
        .flatMap { id1 in nextId.flatMap { id2 in nextId.fmap { id3 in (id1, id2, id3) } } }

    allocateThree.runStateful(0) // ((0, 1, 2), 3)
}

// learn(statefulIdGenerator)

//: [Previous](@previous) | [Next](@next)
