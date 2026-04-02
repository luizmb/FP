import FP

// ============================================================
// STATEFUL<S, A>
//
// Threads mutable state through a sequence of computations
// without passing it explicitly. flatMap wires state in/out.
// Named "Stateful" (not State) to avoid SwiftUI conflicts.
// ============================================================

// MARK: - Construction & Running

func learnStatefulConstruction() {
    let readState = Stateful<Int, Int>  { s in s }
    let increment = Stateful<Int, Void> { s in s += 1 }
    let double    = Stateful<Int, Void> { s in s *= 2 }

    increment.eval(5)          // () — the Void result
    increment.exec(5)          // 6  — the new state
    increment.runStateful(5)   // ((), 6) — both

    readState.runStateful(42)  // (42, 42)
    double.runStateful(3)      // ((), 6)
}
// learnStatefulConstruction()

// MARK: - get / put / modify patterns

func learnStatefulGetPutModify() {
    let getState    = Stateful<Int, Int>  { s in s }
    let putState    = { (n: Int) in Stateful<Int, Void> { s in s = n } }
    let modifyState = { (f: @escaping (Int) -> Int) in Stateful<Int, Void> { s in s = f(s) } }

    getState.runStateful(42)              // (42, 42)
    putState(100).runStateful(42)         // ((), 100)
    modifyState { $0 * 2 }.runStateful(5) // ((), 10)
}
// learnStatefulGetPutModify()

// MARK: - Functor

func learnStatefulFunctor() {
    let s = Stateful<Int, Int> { state in state * 2 }

    let asString = s.fmap { "value: \($0)" }
    asString.eval(5)             // "value: 10"

    let withOp = { "v:\($0)" } <£> s
    withOp.eval(3)               // "v:6"
}
// learnStatefulFunctor()

// MARK: - Monad

func learnStatefulMonad() {
    let getState  = Stateful<Int, Int>  { s in s }
    let increment = Stateful<Int, Void> { s in s += 1 }

    // flatMap — threads state automatically
    let readAfterInc = increment.flatMap { _ in getState }
    readAfterInc.runStateful(0)                        // (1, 1)

    // Three increments then read
    let thrice = increment
        .flatMap { _ in increment }
        .flatMap { _ in increment }
        .flatMap { _ in getState }
    thrice.runStateful(0)                              // (3, 3)

    // bind (curried) + operator
    let step: (Int) -> Stateful<Int, String> = { n in Stateful { s in s = n * 2; return "set \(n*2)" } }
    (getState >>- step).runStateful(5)                 // ("set 10", 10)
}
// learnStatefulMonad()

// MARK: - Practical: stack machine

func learnStatefulStack() {
    typealias Stack = [Int]

    let push: (Int) -> Stateful<Stack, Void> = { n in Stateful { stack in stack.append(n) } }
    let pop  = Stateful<Stack, Int?> { stack in stack.isEmpty ? nil : stack.removeLast() }
    let peek = Stateful<Stack, Int?> { stack in stack.last }

    let program = push(1)
        .flatMap { _ in push(2) }
        .flatMap { _ in push(3) }
        .flatMap { _ in pop }
        .flatMap { popped in push((popped ?? 0) * 10) }

    program.exec([])              // [1, 2, 30]

    let readTop = peek
    readTop.eval([10, 20, 30])    // Optional(30)
}
// learnStatefulStack()

// MARK: - Practical: unique ID generator

func learnStatefulIdGenerator() {
    let nextId = Stateful<Int, Int> { counter in
        let id = counter
        counter += 1
        return id
    }

    let allocateThree = nextId
        .flatMap { id1 in nextId.flatMap { id2 in nextId.fmap { id3 in (id1, id2, id3) } } }

    allocateThree.runStateful(0)   // ((0, 1, 2), 3)
}
// learnStatefulIdGenerator()

//: [Previous](@previous) | [Next](@next)
