import DataStructure
import Testing
import Core

@Suite struct StatefulCoreTests {

    // MARK: - Construction & Execution

    @Test func statefulEval() {
        let s = Stateful<Int, String> { state in
            let result = "\(state)"
            state += 1
            return result
        }
        #expect(s.eval(0) == "0")
    }

    @Test func statefulExec() {
        let s = Stateful<Int, Void> { state in state += 10 }
        #expect(s.exec(5) == 15)
    }

    @Test func statefulRunStateful() {
        let s = Stateful<Int, String> { state in
            let result = "\(state)"
            state *= 2
            return result
        }
        let (value, finalState) = s.runStateful(3)
        #expect(value == "3")
        #expect(finalState == 6)
    }

    @Test func callAsFunction() {
        let s = Stateful<Int, Int> { state in
            let v = state
            state += 1
            return v
        }
        var st = 10
        let result = s(&st)
        #expect(result == 10)
        #expect(st == 11)
    }

    // MARK: - Primitives

    @Test func get() {
        let s = Stateful<Int, Int>.get
        #expect(s.eval(42) == 42)
        #expect(s.exec(42) == 42)
    }

    @Test func gets() {
        let s = Stateful<Int, String>.gets { "\($0)" }
        #expect(s.eval(7) == "7")
    }

    @Test func put() {
        let s = Stateful<Int, Void>.put(99)
        #expect(s.exec(0) == 99)
    }

    @Test func modify() {
        let s = Stateful<Int, Void>.modify { $0 * 3 }
        #expect(s.exec(4) == 12)
    }

    @Test func modifyInPlace() {
        let s = Stateful<[Int], Void>.modifyInPlace { $0.append(42) }
        #expect(s.exec([1, 2]) == [1, 2, 42])
    }

    @Test func pure() {
        let s = Stateful<Int, String>.pure("hello")
        #expect(s.eval(0) == "hello")
        #expect(s.exec(0) == 0)
    }

    // MARK: - Functor

    @Test func fmap() {
        let s = Stateful<Int, Int>.get
        let mapped = s.fmap { $0 * 2 }
        #expect(mapped.eval(5) == 10)
    }

    @Test func mapStateful() {
        let s = Stateful<Int, Int>.get
        let mapped = s.mapStateful { "\($0)" }
        #expect(mapped.eval(3) == "3")
    }

    @Test func staticFmap() {
        let double = Stateful<Int, Int>.fmap { $0 * 2 }
        let s = Stateful<Int, Int>.get
        #expect(double(s).eval(4) == 8)
    }

    // MARK: - Applicative

    @Test func apply() {
        let sf = Stateful<Int, (Int) -> String>.pure { "\($0)" }
        let sa = Stateful<Int, Int>.get
        let result = Stateful<Int, String>.apply(sf, sa)
        #expect(result.eval(7) == "7")
    }

    @Test func seqRight() {
        let incr = Stateful<Int, Void>.modify { $0 + 1 }
        let getValue = Stateful<Int, Int>.get
        let result = incr.seqRight(getValue)
        #expect(result.eval(5) == 6)
        #expect(result.exec(5) == 6)
    }

    @Test func seqLeft() {
        let getValue = Stateful<Int, Int>.get
        let incr = Stateful<Int, Void>.modify { $0 + 1 }
        let result = getValue.seqLeft(incr)
        // returns original value before increment
        #expect(result.eval(5) == 5)
        // but state is still mutated
        #expect(result.exec(5) == 6)
    }

    @Test func liftA2() {
        let sa = Stateful<Int, Int>.get
        let sb = Stateful<Int, Int>.pure(10)
        let combined = Stateful<Int, Int>.liftA2(+)(sa, sb)
        #expect(combined.eval(5) == 15)
    }

    // MARK: - Monad

    @Test func flatMap() {
        let s = Stateful<Int, Int>.get
        let bound = s.flatMap { value in
            Stateful<Int, String> { state in
                state += value
                return "\(value)"
            }
        }
        let (result, finalState) = bound.runStateful(3)
        #expect(result == "3")
        #expect(finalState == 6)
    }

    @Test func bind() {
        let double: (Int) -> Stateful<Int, Int> = { value in
            Stateful { state in
                state += value
                return value * 2
            }
        }
        let s = Stateful<Int, Int>.bind(double)(Stateful<Int, Int>.get)
        let (result, finalState) = s.runStateful(5)
        #expect(result == 10)
        #expect(finalState == 10)
    }

    @Test func kleisli() {
        let addToState: (Int) -> Stateful<Int, Int> = { n in
            Stateful { state in
                state += n
                return state
            }
        }
        let doubleFromState: (Int) -> Stateful<Int, String> = { n in
            Stateful { _ in "\(n * 2)" }
        }
        let composed = Stateful<Int, Int>.kleisli(addToState, doubleFromState)
        #expect(composed(3).eval(10) == "26") // state = 13, result = 13*2 = 26
    }

    @Test func join() {
        let nested = Stateful<Int, Stateful<Int, Int>>.pure(
            Stateful { state in
                let v = state
                state += 1
                return v
            }
        )
        let flat = Stateful.join(nested)
        let (result, finalState) = flat.runStateful(5)
        #expect(result == 5)
        #expect(finalState == 6)
    }

    // MARK: - State threading

    @Test func stateThreadsThroughFlatMap() {
        // Each flatMap step sees the updated state from the previous step
        let program = Stateful<Int, Void>.modify { $0 + 1 }
            .seqRight(.modify { $0 * 2 })
            .seqRight(.modify { $0 + 3 })
        // (0 + 1) * 2 + 3 = 5
        #expect(program.exec(0) == 5)
    }

    @Test func accumulateState() {
        let push: (Int) -> Stateful<[Int], Void> = { value in
            .modifyInPlace { $0.append(value) }
        }
        let program = push(1).seqRight(push(2)).seqRight(push(3))
        #expect(program.exec([]) == [1, 2, 3])
    }
}
