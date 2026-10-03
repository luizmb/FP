// SPDX-License-Identifier: Apache-2.0
import CoreFP
import DataStructure
import Testing

// Monad laws for the transformer binds that take a full-stack continuation (`a -> t m b`):
// `ReaderT r (Writer w)`, `ReaderT r (State s)`, `StateT s (Writer w)` and `ReaderT r NonEmpty`.
// Every law is checked by running both sides with concrete environments / initial states and comparing
// value, log and final state. The applicatives must equal `ap` derived from the same bind.

private let environments = [0, 3, -2]
private let initialStates = [0, 5, -4]

// MARK: - ReaderTWriter

typealias BindLawRW<A> = Reader<Int, Writer<[String], A>>

private func pureRW<A: Sendable>(_ value: A) -> BindLawRW<A> {
    BindLawRW<A>.pure(Writer(value, []))
}

private func expectSameRW<A: Equatable>(
    _ actual: BindLawRW<A>,
    _ expected: BindLawRW<A>,
    sourceLocation: SourceLocation = #_sourceLocation
) {
    for env in environments {
        #expect(actual(env) == expected(env), sourceLocation: sourceLocation)
    }
}

@Suite struct ReaderTWriterBindLawTests {
    let ms: [BindLawRW<Int>] = [
        BindLawRW { env in Writer(env, ["m"]) },
        BindLawRW { env in Writer(env * 10, []) }
    ]
    let f: @Sendable (Int) -> BindLawRW<Int> = { a in BindLawRW { env in Writer(a + env, ["f\(a)"]) } }
    let g: @Sendable (Int) -> BindLawRW<String> = { b in BindLawRW { env in Writer("\(b * env)", ["g\(b)"]) } }

    @Test func leftIdentity() {
        for a in [0, 1, 7] {
            expectSameRW(pureRW(a).flatMapT(f), f(a))
        }
    }

    @Test func rightIdentity() {
        for m in ms {
            expectSameRW(m.flatMapT(pureRW), m)
        }
    }

    @Test func associativity() {
        let f = f
        let g = g
        for m in ms {
            expectSameRW(m.flatMapT(f).flatMapT(g), m.flatMapT { a in f(a).flatMapT(g) })
        }
    }

    @Test func applicativeEqualsAp() {
        let rf = BindLawRW<@Sendable (Int) -> Int> { env in Writer({ $0 + env }, ["fn"]) }
        let rb = BindLawRW<String> { env in Writer("b\(env)", ["rhs"]) }
        for ra in ms {
            expectSameRW(applyReaderWriter(rf, ra), rf.flatMapT { fn in ra.mapT(fn) })
            expectSameRW(
                liftA2ReaderWriter { (a: Int, b: String) in "\(a)\(b)" }(ra, rb),
                ra.flatMapT { a in rb.mapT { b in "\(a)\(b)" } }
            )
            expectSameRW(seqRightReaderWriter(ra, rb), ra.flatMapT(const(rb)))
            expectSameRW(seqLeftReaderWriter(ra, rb), ra.flatMapT { a in rb.mapT(const(a)) })
        }
    }

    @Test func continuationReadsEnvironmentAndLogs() {
        let m = BindLawRW<Int> { env in Writer(env + 1, ["start"]) }
        let result = m.flatMapT { a in BindLawRW<String> { env in Writer("\(a)/\(env)", ["saw env \(env)"]) } }
        #expect(result(4) == Writer("5/4", ["start", "saw env 4"]))
    }

    @Test func bindTAndKleisliTAgreeWithFlatMapT() {
        for m in ms {
            expectSameRW(BindLawRW<Int>.bindT(f)(m), m.flatMapT(f))
        }
        for a in [0, 2] {
            expectSameRW(kleisliT(f, g)(a), f(a).flatMapT(g))
        }
    }
}

// MARK: - ReaderTStateful

typealias BindLawRS<A> = Reader<Int, Stateful<Int, A>>

private func pureRS<A: Sendable>(_ value: A) -> BindLawRS<A> {
    BindLawRS<A>.pure(.pure(value))
}

private func expectSameRS<A: Equatable>(
    _ actual: BindLawRS<A>,
    _ expected: BindLawRS<A>,
    sourceLocation: SourceLocation = #_sourceLocation
) {
    for env in environments {
        for initial in initialStates {
            let (actualValue, actualState) = actual(env).runStateful(initial)
            let (expectedValue, expectedState) = expected(env).runStateful(initial)
            #expect(actualValue == expectedValue, sourceLocation: sourceLocation)
            #expect(actualState == expectedState, sourceLocation: sourceLocation)
        }
    }
}

@Suite struct ReaderTStatefulBindLawTests {
    let ms: [BindLawRS<Int>] = [
        BindLawRS { env in
            Stateful { s in
                s += 1
                return env * 10 + s
            }
        },
        BindLawRS { env in Stateful { s in s * env } }
    ]
    let f: @Sendable (Int) -> BindLawRS<Int> = { a in
        BindLawRS { env in
            Stateful { s in
                s = s * 2 + env
                return a + s
            }
        }
    }

    let g: @Sendable (Int) -> BindLawRS<String> = { b in
        BindLawRS { env in
            Stateful { s in
                s -= b
                return "\(b):\(env):\(s)"
            }
        }
    }

    @Test func leftIdentity() {
        for a in [0, 1, 7] {
            expectSameRS(pureRS(a).flatMapT(f), f(a))
        }
    }

    @Test func rightIdentity() {
        for m in ms {
            expectSameRS(m.flatMapT(pureRS), m)
        }
    }

    @Test func associativity() {
        let f = f
        let g = g
        for m in ms {
            expectSameRS(m.flatMapT(f).flatMapT(g), m.flatMapT { a in f(a).flatMapT(g) })
        }
    }

    @Test func applicativeEqualsAp() {
        let rf = BindLawRS<@Sendable (Int) -> Int> { env in
            Stateful { s in
                s += 100
                return { $0 * env }
            }
        }
        let rb = BindLawRS<String> { env in
            Stateful { s in
                s *= 3
                return "b\(env)"
            }
        }
        for ra in ms {
            expectSameRS(applyReaderStateful(rf, ra), rf.flatMapT { fn in ra.mapT(fn) })
            expectSameRS(
                liftA2ReaderStateful { (a: Int, b: String) in "\(a)\(b)" }(ra, rb),
                ra.flatMapT { a in rb.mapT { b in "\(a)\(b)" } }
            )
            expectSameRS(seqRightReaderStateful(ra, rb), ra.flatMapT(const(rb)))
            expectSameRS(seqLeftReaderStateful(ra, rb), ra.flatMapT { a in rb.mapT(const(a)) })
        }
    }

    @Test func continuationReadsEnvironmentAndTouchesState() {
        let m = BindLawRS<Int> { env in
            Stateful { s in
                s += env
                return s
            }
        }
        let result = m.flatMapT { a in
            BindLawRS<String> { env in
                Stateful { s in
                    s *= env
                    return "\(a)/\(env)"
                }
            }
        }
        let (value, finalState) = result(3).runStateful(1)
        #expect(value == "4/3")
        #expect(finalState == 12)
    }

    @Test func bindTAndKleisliTAgreeWithFlatMapT() {
        for m in ms {
            expectSameRS(BindLawRS<Int>.bindT(f)(m), m.flatMapT(f))
        }
        for a in [0, 2] {
            expectSameRS(kleisliT(f, g)(a), f(a).flatMapT(g))
        }
    }
}

// MARK: - StatefulTWriter

typealias BindLawSW<A> = Stateful<Int, Writer<[String], A>>

private func pureSW<A: Sendable>(_ value: A) -> BindLawSW<A> {
    BindLawSW<A>.pure(Writer(value, []))
}

private func expectSameSW<A: Equatable>(
    _ actual: BindLawSW<A>,
    _ expected: BindLawSW<A>,
    sourceLocation: SourceLocation = #_sourceLocation
) {
    for initial in initialStates {
        let (actualWriter, actualState) = actual.runStateful(initial)
        let (expectedWriter, expectedState) = expected.runStateful(initial)
        #expect(actualWriter == expectedWriter, sourceLocation: sourceLocation)
        #expect(actualState == expectedState, sourceLocation: sourceLocation)
    }
}

@Suite struct StatefulTWriterBindLawTests {
    let ms: [BindLawSW<Int>] = [
        BindLawSW { s in
            s += 1
            return Writer(s, ["m"])
        },
        BindLawSW { s in Writer(s * 2, []) }
    ]
    let f: @Sendable (Int) -> BindLawSW<Int> = { a in
        BindLawSW { s in
            s = s * 3 + a
            return Writer(a - s, ["f\(a)"])
        }
    }

    let g: @Sendable (Int) -> BindLawSW<String> = { b in
        BindLawSW { s in
            s -= 1
            return Writer("\(b):\(s)", ["g\(b)"])
        }
    }

    @Test func leftIdentity() {
        for a in [0, 1, 7] {
            expectSameSW(pureSW(a).flatMapT(f), f(a))
        }
    }

    @Test func rightIdentity() {
        for m in ms {
            expectSameSW(m.flatMapT(pureSW), m)
        }
    }

    @Test func associativity() {
        let f = f
        let g = g
        for m in ms {
            expectSameSW(m.flatMapT(f).flatMapT(g), m.flatMapT { a in f(a).flatMapT(g) })
        }
    }

    @Test func applicativeEqualsAp() {
        let sf = BindLawSW<@Sendable (Int) -> Int> { s in
            s += 100
            return Writer({ $0 * 2 }, ["fn"])
        }
        let sb = BindLawSW<String> { s in
            s *= 3
            return Writer("b\(s)", ["rhs"])
        }
        for sa in ms {
            expectSameSW(applyStatefulWriter(sf, sa), sf.flatMapT { fn in sa.mapT(fn) })
            expectSameSW(
                liftA2StatefulWriter { (a: Int, b: String) in "\(a)\(b)" }(sa, sb),
                sa.flatMapT { a in sb.mapT { b in "\(a)\(b)" } }
            )
            expectSameSW(seqRightStatefulWriter(sa, sb), sa.flatMapT(const(sb)))
            expectSameSW(seqLeftStatefulWriter(sa, sb), sa.flatMapT { a in sb.mapT(const(a)) })
        }
    }

    @Test func continuationTouchesStateAndLogs() {
        let m = BindLawSW<Int> { s in
            s += 1
            return Writer(s, ["start"])
        }
        let result = m.flatMapT { a in
            BindLawSW<String> { s in
                s *= 10
                return Writer("\(a)", ["state was \(s / 10)"])
            }
        }
        let (writer, finalState) = result.runStateful(4)
        #expect(writer == Writer("5", ["start", "state was 5"]))
        #expect(finalState == 50)
    }

    @Test func bindTAndKleisliTAgreeWithFlatMapT() {
        for m in ms {
            expectSameSW(BindLawSW<Int>.bindT(f)(m), m.flatMapT(f))
        }
        for a in [0, 2] {
            expectSameSW(kleisliT(f, g)(a), f(a).flatMapT(g))
        }
    }
}

// MARK: - ReaderTNonEmpty

typealias BindLawRN<A> = Reader<Int, NonEmpty<A>>

private func pureRN<A: Sendable>(_ value: A) -> BindLawRN<A> {
    BindLawRN<A>.pure(NonEmpty(head: value))
}

private func expectSameRN<A: Equatable & Sendable>(
    _ actual: BindLawRN<A>,
    _ expected: BindLawRN<A>,
    sourceLocation: SourceLocation = #_sourceLocation
) {
    for env in environments {
        #expect(actual(env) == expected(env), sourceLocation: sourceLocation)
    }
}

@Suite struct ReaderTNonEmptyBindLawTests {
    let ms: [BindLawRN<Int>] = [
        BindLawRN { env in NonEmpty(head: env, tail: [env + 1]) },
        BindLawRN { env in NonEmpty(head: env * 10) }
    ]
    let f: @Sendable (Int) -> BindLawRN<Int> = { a in BindLawRN { env in NonEmpty(head: a, tail: [a + env]) } }
    let g: @Sendable (Int) -> BindLawRN<String> = { b in BindLawRN { env in NonEmpty(head: "\(b)", tail: ["\(b * env)"]) } }

    @Test func leftIdentity() {
        for a in [0, 1, 7] {
            expectSameRN(pureRN(a).flatMapT(f), f(a))
        }
    }

    @Test func rightIdentity() {
        for m in ms {
            expectSameRN(m.flatMapT(pureRN), m)
        }
    }

    @Test func associativity() {
        let f = f
        let g = g
        for m in ms {
            expectSameRN(m.flatMapT(f).flatMapT(g), m.flatMapT { a in f(a).flatMapT(g) })
        }
    }

    @Test func applicativeEqualsAp() {
        let rf = BindLawRN<@Sendable (Int) -> Int> { env in NonEmpty(head: { $0 + env }, tail: [{ $0 * 2 }]) }
        let rb = BindLawRN<String> { env in NonEmpty(head: "x\(env)", tail: ["y"]) }
        for ra in ms {
            expectSameRN(applyReaderNonEmpty(rf, ra), rf.flatMapT { fn in ra.mapT(fn) })
            expectSameRN(
                liftA2ReaderNonEmpty { (a: Int, b: String) in "\(a)\(b)" }(ra, rb),
                ra.flatMapT { a in rb.mapT { b in "\(a)\(b)" } }
            )
            expectSameRN(seqRightReaderNonEmpty(ra, rb), ra.flatMapT(const(rb)))
            expectSameRN(seqLeftReaderNonEmpty(ra, rb), ra.flatMapT { a in rb.mapT(const(a)) })
        }
    }

    @Test func continuationReadsEnvironment() {
        let m = BindLawRN<Int>(const(NonEmpty(head: 1, tail: [2])))
        let result = m.flatMapT { a in BindLawRN<String> { env in NonEmpty(head: "\(a)", tail: ["\(a)@\(env)"]) } }
        #expect(result(9) == NonEmpty(head: "1", tail: ["1@9", "2", "2@9"]))
    }

    @Test func bindTAndKleisliTAgreeWithFlatMapT() {
        for m in ms {
            expectSameRN(BindLawRN<Int>.bindT(f)(m), m.flatMapT(f))
        }
        for a in [0, 2] {
            expectSameRN(kleisliT(f, g)(a), f(a).flatMapT(g))
        }
    }
}
