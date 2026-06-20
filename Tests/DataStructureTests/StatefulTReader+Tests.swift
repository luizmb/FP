// SPDX-License-Identifier: Apache-2.0
import CoreFP
import DataStructure
import Testing

@Suite struct StatefulReaderTests {
    struct Env {
        let multiplier: Int
    }

    // MARK: - Stateful<S, Reader<Env, A>> — State as outer, Reader as inner

    @Test func mapT() {
        let s = Stateful<Int, Reader<Env, Int>>.pure(Reader { env in env.multiplier })
        let mapped = s.mapT { $0 * 2 }
        let env = Env(multiplier: 5)
        #expect(mapped.eval(0)(env) == 10)
    }

    @Test func mapTThreadsState() {
        let s = Stateful<Int, Reader<Env, Int>> { state in
            let v = state
            state += 1
            return Reader { env in env.multiplier + v }
        }
        let mapped = s.mapT { "\($0)" }
        let env = Env(multiplier: 10)
        // eval: state starts at 2, run &s → v=2, state becomes 3, returns Reader{env in 10+2=12}
        // mapT applies fn: "12"
        let (output, finalState) = mapped.runStateful(2)
        #expect(output(env) == "12")
        #expect(finalState == 3)
    }

    @Test func applyStatefulReaderBoth() {
        let fn: @Sendable (Int) -> String = { "\($0)" }
        let sf = Stateful<Int, Reader<Env, @Sendable (Int) -> String>>.pure(
            Reader(const(fn))
        )
        let sa = Stateful<Int, Reader<Env, Int>>.pure(
            Reader { env in env.multiplier }
        )
        let result = applyStatefulReader(sf, sa)
        let env = Env(multiplier: 7)
        #expect(result.eval(0)(env) == "7")
    }

    @Test func liftA2StatefulReaderBoth() {
        let sa = Stateful<Int, Reader<Env, Int>>.pure(Reader { env in env.multiplier })
        let sb = Stateful<Int, Reader<Env, Int>>.pure(Reader(const(10)))
        let result = liftA2StatefulReader(+)(sa, sb)
        let env = Env(multiplier: 5)
        #expect(result.eval(0)(env) == 15)
    }

    // MARK: - Reader<Env, Stateful<S, A>> — Reader as outer, Stateful as inner

    @Test func readerTStatefulMapT() {
        let r = Reader<Env, Stateful<Int, Int>> { env in
            .pure(env.multiplier)
        }
        let mapped = r.mapT { $0 * 3 }
        let env = Env(multiplier: 4)
        #expect(mapped(env).eval(0) == 12)
    }

    @Test func readerTStatefulFlatMapT() {
        let r = Reader<Env, Stateful<Int, Int>> { env in
            .pure(env.multiplier)
        }
        let result = r.flatMapT { value in
            Stateful<Int, String>.pure("\(value)")
        }
        let env = Env(multiplier: 9)
        #expect(result(env).eval(0) == "9")
    }

    @Test func readerTStatefulFlatMapTThreadsState() {
        let r = Reader<Env, Stateful<Int, Int>> { env in
            Stateful { state in
                let v = state
                state += env.multiplier
                return v
            }
        }
        let result = r.flatMapT { value in
            Stateful<Int, String> { state in
                state += value
                return "\(value)"
            }
        }
        let env = Env(multiplier: 3)
        // env.multiplier=3: first stateful: v=0, state→3, returns 0
        // flatMapT fn(0): state += 0 → 3, returns "0"
        let (output, finalState) = result(env).runStateful(0)
        #expect(output == "0")
        #expect(finalState == 3)
    }

    @Test func applyReaderStatefulTest() {
        let fn2: @Sendable (Int) -> String = { "\($0)" }
        let rf = Reader<Env, Stateful<Int, @Sendable (Int) -> String>>(const(.pure(fn2)))
        let ra = Reader<Env, Stateful<Int, Int>> { env in .pure(env.multiplier) }
        let result = DataStructure.applyReaderStateful(rf, ra)
        let env = Env(multiplier: 5)
        #expect(result(env).eval(0) == "5")
    }

    @Test func seqRightReaderStatefulTest() {
        let lhs = Reader<Env, Stateful<Int, Int>>(const(.pure(1)))
        let rhs = Reader<Env, Stateful<Int, String>>(const(.pure("hello")))
        let result = DataStructure.seqRightReaderStateful(lhs, rhs)
        let env = Env(multiplier: 0)
        #expect(result(env).eval(0) == "hello")
    }

    @Test func seqLeftReaderStatefulTest() {
        let lhs = Reader<Env, Stateful<Int, Int>>(const(.pure(99)))
        let rhs = Reader<Env, Stateful<Int, String>>(const(.pure("ignored")))
        let result = DataStructure.seqLeftReaderStateful(lhs, rhs)
        let env = Env(multiplier: 0)
        #expect(result(env).eval(0) == 99)
    }
}
