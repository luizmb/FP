import FP

// ============================================================
// STATEFUL<S, A>
// run          :: Stateful<S, A> -> (inout S) -> A
// eval         :: S -> A          (run & return value, discard state)
// exec         :: S -> S          (run & return state, discard value)
// runStateful  :: S -> (A, S)     (run & return both)
//
// Stateful threads a mutable state S through a sequence of
// computations without you having to pass it explicitly.
// Each step receives and returns the state; flatMap wires them.
//
// Haskell equivalent: State s a
// Named "Stateful" (not State) to avoid SwiftUI conflicts.
// ============================================================

// MARK: - Construction & Running

// --- Basic: a computation that reads state and returns a value ---
// let readState = Stateful<Int, Int> { state in state }

// --- A computation that modifies state (returns Void) ---
// let increment = Stateful<Int, Void> { state in state += 1 }
// let double    = Stateful<Int, Void> { state in state *= 2 }

// --- Run it ---
// increment.eval(5)                        // () — the Void value
// increment.exec(5)                        // 6  — the new state
// increment.runStateful(5)                 // ((), 6) — both


// MARK: - get / put / modify patterns
// These aren't built-in, but trivial to express:

// let getState    = Stateful<Int, Int>  { s in s }
// let putState    = { (new: Int) in Stateful<Int, Void> { s in s = new } }
// let modifyState = { (f: @escaping (Int) -> Int) in Stateful<Int, Void> { s in s = f(s) } }

// getState.runStateful(42)                 // (42, 42)
// putState(100).runStateful(42)            // ((), 100)
// modifyState { $0 * 2 }.runStateful(5)   // ((), 10)


// MARK: - Functor

// let s = Stateful<Int, Int> { state in state * 2 }

// --- Named function ---
// s.fmap { "\($0)" }                       // Stateful<Int, String> — returns "\(state * 2)"

// --- Operators ---
// { "\($0)" } <£> s
// s <&> { "\($0)" }

// // Run the mapped computation:
// s.fmap { "\($0)" }.eval(5)              // "10"


// MARK: - Monad (threads state automatically through flatMap)

// let getState    = Stateful<Int, Int>  { s in s }
// let increment   = Stateful<Int, Void> { s in s += 1 }
// let putState    = { (new: Int) in Stateful<Int, Void> { s in s = new } }

// --- flatMap: read then put double the value ---
// let readThenDouble = getState.flatMap { n in putState(n * 2) }
// readThenDouble.runStateful(5)            // ((), 10)

// --- Chain multiple steps ---
// let pipeline = increment
//     .flatMap { _ in increment }
//     .flatMap { _ in getState }
// pipeline.runStateful(0)                  // (2, 2) — incremented twice, then read

// --- bind (curried) ---
// let step: (Int) -> Stateful<Int, String> = { n in Stateful { s in s = n * 2; return "set to \(n * 2)" } }
// Stateful<Int, Int>.bind(step)(getState).runStateful(5)  // ("set to 10", 10)

// --- Operator ---
// (getState >>- step).runStateful(5)       // ("set to 10", 10)


// MARK: - Practical: stack machine

// enum StackOp {
//     case push(Int)
//     case pop
// }

// typealias Stack = [Int]

// let push: (Int) -> Stateful<Stack, Void> = { n in Stateful { stack in stack.append(n) } }
// let pop  = Stateful<Stack, Int?> { stack in stack.isEmpty ? nil : stack.removeLast() }
// let peek = Stateful<Stack, Int?> { stack in stack.last }

// --- Run a sequence of stack operations ---
// let program = push(1)
//     .flatMap { _ in push(2) }
//     .flatMap { _ in push(3) }
//     .flatMap { _ in pop }
//     .flatMap { popped in push((popped ?? 0) * 10) }

// program.runStateful([])                  // ((), [1, 2, 30])
// program.exec([])                         // [1, 2, 30]


// MARK: - Practical: unique ID generator

// let nextId = Stateful<Int, Int> { counter in
//     let id = counter
//     counter += 1
//     return id
// }

// let allocateThree = nextId
//     .flatMap { id1 in nextId.flatMap { id2 in nextId.fmap { id3 in (id1, id2, id3) } } }

// allocateThree.runStateful(0)             // ((0, 1, 2), 3)

//: [Previous](@previous) | [Next](@next)
