import CoreFP
import DataStructure
import Testing

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

    // MARK: - Zip

    @Test func zipProducesTuple() {
        let sa = Stateful<Int, Int>.get
        let sb = Stateful<Int, String>.gets { "\($0)" }
        #expect(Stateful<Int, (Int, String)>.zip(sa, sb).eval(7) == (7, "7"))
    }

    @Test func zipThreadsStateLeftToRight() {
        // sa reads then increments; sb reads the already-incremented state
        let sa = Stateful<Int, Int> { s in let v = s; s += 1; return v }
        let sb = Stateful<Int, Int>.get
        let result = Stateful<Int, (Int, Int)>.zip(sa, sb)
        // state = 0: sa returns 0, state becomes 1; sb returns 1
        #expect(result.eval(0) == (0, 1))
        #expect(result.exec(0) == 1)
    }

    @Test func zip3ProducesTriple() {
        let sa = Stateful<Int, Int>.pure(1)
        let sb = Stateful<Int, String>.pure("a")
        let sc = Stateful<Int, Bool>.pure(true)
        #expect(Stateful<Int, (Int, String, Bool)>.zip3(sa, sb, sc).eval(0) == (1, "a", true))
    }

    @Test func zip3ThreadsStateLeftToRight() {
        let s1 = Stateful<Int, Int> { s in let v = s; s += 1; return v }
        let s2 = Stateful<Int, Int> { s in let v = s; s += 10; return v }
        let s3 = Stateful<Int, Int>.get
        let result = Stateful<Int, (Int, Int, Int)>.zip3(s1, s2, s3)
        // state=0: s1 returns 0, state→1; s2 returns 1, state→11; s3 reads 11
        #expect(result.eval(0) == (0, 1, 11))
        #expect(result.exec(0) == 11)
    }

    @Test func zip4ProducesQuadruple() {
        let sa = Stateful<Int, Int>.pure(1)
        let sb = Stateful<Int, String>.pure("a")
        let sc = Stateful<Int, Bool>.pure(true)
        let sd = Stateful<Int, Double>.pure(2.5)
        #expect(Stateful<Int, (Int, String, Bool, Double)>.zip4(sa, sb, sc, sd).eval(0) == (1, "a", true, 2.5))
    }

    @Test func zip4ThreadsStateLeftToRight() {
        let s1 = Stateful<Int, Int> { s in let v = s; s += 1; return v }
        let s2 = Stateful<Int, Int> { s in let v = s; s += 10; return v }
        let s3 = Stateful<Int, Int> { s in let v = s; s += 100; return v }
        let s4 = Stateful<Int, Int>.get
        let result = Stateful<Int, (Int, Int, Int, Int)>.zip4(s1, s2, s3, s4)
        // state=0: s1→0,state=1; s2→1,state=11; s3→11,state=111; s4 reads 111
        #expect(result.eval(0) == (0, 1, 11, 111))
        #expect(result.exec(0) == 111)
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

    // MARK: - join / void

    @Test func joinFreeFunction() {
        let nested = Stateful<Int, Stateful<Int, Int>> { s in
            s += 1
            return Stateful<Int, Int> { s in
                let v = s
                s *= 2
                return v
            }
        }
        // state starts at 3: outer runs → state=4, returns inner
        // inner runs → returns 4, state becomes 8
        let (value, finalState) = DataStructure.join(nested).runStateful(3)
        #expect(value == 4)
        #expect(finalState == 8)
    }

    @Test func voidFreeFunction() {
        let stateful = Stateful<Int, Int> { s in s += 1; return s }
        let voided = DataStructure.void(stateful)
        let (_, finalState) = voided.runStateful(5)
        #expect(finalState == 6) // state still threads through
    }
}
