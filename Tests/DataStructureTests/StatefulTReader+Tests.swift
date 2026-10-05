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
        let mapped = s.statefulT.map { $0 * 2 }
        let env = Env(multiplier: 5)
        #expect(mapped.rawValue.eval(0)(env) == 10)
    }

    @Test func mapTThreadsState() {
        let s = Stateful<Int, Reader<Env, Int>> { state in
            let v = state
            state += 1
            return Reader { env in env.multiplier + v }
        }
        let mapped = s.statefulT.map { "\($0)" }
        let env = Env(multiplier: 10)
        // eval: state starts at 2, run &s → v=2, state becomes 3, returns Reader{env in 10+2=12}
        // mapT applies fn: "12"
        let (output, finalState) = mapped.rawValue.runStateful(2)
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
        let result = StatefulTReader.apply(sf.statefulT, sa.statefulT).rawValue
        let env = Env(multiplier: 7)
        #expect(result.eval(0)(env) == "7")
    }

    @Test func liftA2StatefulReaderBoth() {
        let sa = Stateful<Int, Reader<Env, Int>>.pure(Reader { env in env.multiplier })
        let sb = Stateful<Int, Reader<Env, Int>>.pure(Reader(const(10)))
        let result = StatefulTReader.liftA2(+)(sa.statefulT, sb.statefulT).rawValue
        let env = Env(multiplier: 5)
        #expect(result.eval(0)(env) == 15)
    }

    // MARK: - Reader<Env, Stateful<S, A>> — Reader as outer, Stateful as inner

    @Test func readerTStatefulMap() {
        let r = Reader<Env, Stateful<Int, Int>> { env in
            .pure(env.multiplier)
        }
        let mapped = r.readerT.map { $0 * 3 }.rawValue
        let env = Env(multiplier: 4)
        #expect(mapped(env).eval(0) == 12)
    }

    @Test func readerTStatefulFlatMap() {
        let r = Reader<Env, Stateful<Int, Int>> { env in
            .pure(env.multiplier)
        }
        let result = r.readerT.flatMap { value in
            ReaderTStateful(Reader<Env, Stateful<Int, String>> { env in .pure("\(value)x\(env.multiplier)") })
        }.rawValue
        let env = Env(multiplier: 9)
        #expect(result(env).eval(0) == "9x9")
    }

    @Test func readerTStatefulFlatMapThreadsState() {
        let r = Reader<Env, Stateful<Int, Int>> { env in
            Stateful { state in
                let v = state
                state += env.multiplier
                return v
            }
        }
        let result = r.readerT.flatMap { value in
            ReaderTStateful(Reader<Env, Stateful<Int, String>> { env in
                Stateful<Int, String> { state in
                    state *= env.multiplier
                    return "\(value)"
                }
            })
        }.rawValue
        let env = Env(multiplier: 3)
        // env.multiplier=3: first stateful: v=1, state→4, returns 1
        // continuation (same env): state *= 3 → 12, returns "1"
        let (output, finalState) = result(env).runStateful(1)
        #expect(output == "1")
        #expect(finalState == 12)
    }

    @Test func applyReaderStatefulTest() {
        let fn2: @Sendable (Int) -> String = { "\($0)" }
        let rf = Reader<Env, Stateful<Int, @Sendable (Int) -> String>>(const(.pure(fn2)))
        let ra = Reader<Env, Stateful<Int, Int>> { env in .pure(env.multiplier) }
        let result = ReaderTStateful<Env, Int, String>.apply(rf.readerT, ra.readerT).rawValue
        let env = Env(multiplier: 5)
        #expect(result(env).eval(0) == "5")
    }

    @Test func seqRightReaderStatefulTest() {
        let lhs = Reader<Env, Stateful<Int, Int>>(const(.pure(1)))
        let rhs = Reader<Env, Stateful<Int, String>>(const(.pure("hello")))
        let result = lhs.readerT.seqRight(rhs.readerT).rawValue
        let env = Env(multiplier: 0)
        #expect(result(env).eval(0) == "hello")
    }

    @Test func seqLeftReaderStatefulTest() {
        let lhs = Reader<Env, Stateful<Int, Int>>(const(.pure(99)))
        let rhs = Reader<Env, Stateful<Int, String>>(const(.pure("ignored")))
        let result = lhs.readerT.seqLeft(rhs.readerT).rawValue
        let env = Env(multiplier: 0)
        #expect(result(env).eval(0) == 99)
    }
}
