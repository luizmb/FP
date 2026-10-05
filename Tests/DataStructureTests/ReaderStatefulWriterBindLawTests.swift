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
typealias StackRW<A> = ReaderTWriter<Int, [String], A>

private func pureRW<A: Sendable>(_ value: A) -> StackRW<A> {
    StackRW<A>.pure(value)
}

private func expectSameRW<A: Equatable>(
    _ actual: StackRW<A>,
    _ expected: StackRW<A>,
    sourceLocation: SourceLocation = #_sourceLocation
) {
    for env in environments {
        #expect(actual.rawValue(env) == expected.rawValue(env), sourceLocation: sourceLocation)
    }
}

@Suite struct ReaderTWriterBindLawTests {
    let ms: [StackRW<Int>] = [
        StackRW(BindLawRW { env in Writer(env, ["m"]) }),
        StackRW(BindLawRW { env in Writer(env * 10, []) })
    ]
    let f: @Sendable (Int) -> StackRW<Int> = { a in StackRW(BindLawRW { env in Writer(a + env, ["f\(a)"]) }) }
    let g: @Sendable (Int) -> StackRW<String> = { b in StackRW(BindLawRW { env in Writer("\(b * env)", ["g\(b)"]) }) }

    @Test func leftIdentity() {
        for a in [0, 1, 7] {
            expectSameRW(pureRW(a).flatMap(f), f(a))
        }
    }

    @Test func rightIdentity() {
        for m in ms {
            expectSameRW(m.flatMap(pureRW), m)
        }
    }

    @Test func associativity() {
        let f = f
        let g = g
        for m in ms {
            expectSameRW(m.flatMap(f).flatMap(g), m.flatMap { a in f(a).flatMap(g) })
        }
    }

    @Test func applicativeEqualsAp() {
        let rf = StackRW(BindLawRW<@Sendable (Int) -> Int> { env in Writer({ $0 + env }, ["fn"]) })
        let rb = StackRW(BindLawRW<String> { env in Writer("b\(env)", ["rhs"]) })
        for ra in ms {
            expectSameRW(StackRW<Int>.apply(rf, ra), rf.flatMap { fn in ra.map(fn) })
            expectSameRW(
                StackRW<String>.liftA2 { (a: Int, b: String) in "\(a)\(b)" }(ra, rb),
                ra.flatMap { a in rb.map { b in "\(a)\(b)" } }
            )
            expectSameRW(ra.seqRight(rb), ra.flatMap(const(rb)))
            expectSameRW(ra.seqLeft(rb), ra.flatMap { a in rb.map(const(a)) })
        }
    }

    @Test func continuationReadsEnvironmentAndLogs() {
        let m = StackRW(BindLawRW<Int> { env in Writer(env + 1, ["start"]) })
        let result = m.flatMap { a in StackRW(BindLawRW<String> { env in Writer("\(a)/\(env)", ["saw env \(env)"]) }) }
        #expect(result.rawValue(4) == Writer("5/4", ["start", "saw env 4"]))
    }

    @Test func bindAndKleisliAgreeWithFlatMap() {
        for m in ms {
            expectSameRW(StackRW<Int>.bind(f)(m), m.flatMap(f))
        }
        for a in [0, 2] {
            expectSameRW(StackRW<Int>.kleisli(f, g)(a), f(a).flatMap(g))
        }
    }
}

// MARK: - ReaderTStateful

typealias BindLawRS<A> = Reader<Int, Stateful<Int, A>>
typealias StackRS<A> = ReaderTStateful<Int, Int, A>

private func pureRS<A: Sendable>(_ value: A) -> StackRS<A> {
    StackRS<A>.pure(value)
}

private func expectSameRS<A: Equatable>(
    _ actual: StackRS<A>,
    _ expected: StackRS<A>,
    sourceLocation: SourceLocation = #_sourceLocation
) {
    for env in environments {
        for initial in initialStates {
            let (actualValue, actualState) = actual.rawValue(env).runStateful(initial)
            let (expectedValue, expectedState) = expected.rawValue(env).runStateful(initial)
            #expect(actualValue == expectedValue, sourceLocation: sourceLocation)
            #expect(actualState == expectedState, sourceLocation: sourceLocation)
        }
    }
}

@Suite struct ReaderTStatefulBindLawTests {
    let ms: [StackRS<Int>] = [
        StackRS(BindLawRS { env in
            Stateful { s in
                s += 1
                return env * 10 + s
            }
        }),
        StackRS(BindLawRS { env in Stateful { s in s * env } })
    ]
    let f: @Sendable (Int) -> StackRS<Int> = { a in
        StackRS(BindLawRS { env in
            Stateful { s in
                s = s * 2 + env
                return a + s
            }
        })
    }

    let g: @Sendable (Int) -> StackRS<String> = { b in
        StackRS(BindLawRS { env in
            Stateful { s in
                s -= b
                return "\(b):\(env):\(s)"
            }
        })
    }

    @Test func leftIdentity() {
        for a in [0, 1, 7] {
            expectSameRS(pureRS(a).flatMap(f), f(a))
        }
    }

    @Test func rightIdentity() {
        for m in ms {
            expectSameRS(m.flatMap(pureRS), m)
        }
    }

    @Test func associativity() {
        let f = f
        let g = g
        for m in ms {
            expectSameRS(m.flatMap(f).flatMap(g), m.flatMap { a in f(a).flatMap(g) })
        }
    }

    @Test func applicativeEqualsAp() {
        let rf = StackRS(BindLawRS<@Sendable (Int) -> Int> { env in
            Stateful { s in
                s += 100
                return { $0 * env }
            }
        })
        let rb = StackRS(BindLawRS<String> { env in
            Stateful { s in
                s *= 3
                return "b\(env)"
            }
        })
        for ra in ms {
            expectSameRS(StackRS<Int>.apply(rf, ra), rf.flatMap { fn in ra.map(fn) })
            expectSameRS(
                StackRS<String>.liftA2 { (a: Int, b: String) in "\(a)\(b)" }(ra, rb),
                ra.flatMap { a in rb.map { b in "\(a)\(b)" } }
            )
            expectSameRS(ra.seqRight(rb), ra.flatMap(const(rb)))
            expectSameRS(ra.seqLeft(rb), ra.flatMap { a in rb.map(const(a)) })
        }
    }

    @Test func continuationReadsEnvironmentAndTouchesState() {
        let m = StackRS(BindLawRS<Int> { env in
            Stateful { s in
                s += env
                return s
            }
        })
        let result = m.flatMap { a in
            StackRS(BindLawRS<String> { env in
                Stateful { s in
                    s *= env
                    return "\(a)/\(env)"
                }
            })
        }
        let (value, finalState) = result.rawValue(3).runStateful(1)
        #expect(value == "4/3")
        #expect(finalState == 12)
    }

    @Test func bindAndKleisliAgreeWithFlatMap() {
        for m in ms {
            expectSameRS(StackRS<Int>.bind(f)(m), m.flatMap(f))
        }
        for a in [0, 2] {
            expectSameRS(StackRS<Int>.kleisli(f, g)(a), f(a).flatMap(g))
        }
    }
}

// MARK: - StatefulTWriter

typealias BindLawSW<A> = StatefulTWriter<Int, [String], A>

private func pureSW<A: Sendable>(_ value: A) -> BindLawSW<A> {
    BindLawSW<A>(.pure(Writer(value, [])))
}

private func stepSW<A>(_ run: @escaping @Sendable (inout Int) -> Writer<[String], A>) -> BindLawSW<A> {
    BindLawSW<A>(Stateful(run))
}

private func expectSameSW<A: Equatable>(
    _ actual: BindLawSW<A>,
    _ expected: BindLawSW<A>,
    sourceLocation: SourceLocation = #_sourceLocation
) {
    for initial in initialStates {
        let (actualWriter, actualState) = actual.rawValue.runStateful(initial)
        let (expectedWriter, expectedState) = expected.rawValue.runStateful(initial)
        #expect(actualWriter == expectedWriter, sourceLocation: sourceLocation)
        #expect(actualState == expectedState, sourceLocation: sourceLocation)
    }
}

@Suite struct StatefulTWriterBindLawTests {
    let ms: [BindLawSW<Int>] = [
        stepSW { s in
            s += 1
            return Writer(s, ["m"])
        },
        stepSW { s in Writer(s * 2, []) }
    ]
    let f: @Sendable (Int) -> BindLawSW<Int> = { a in
        stepSW { s in
            s = s * 3 + a
            return Writer(a - s, ["f\(a)"])
        }
    }

    let g: @Sendable (Int) -> BindLawSW<String> = { b in
        stepSW { s in
            s -= 1
            return Writer("\(b):\(s)", ["g\(b)"])
        }
    }

    @Test func leftIdentity() {
        for a in [0, 1, 7] {
            expectSameSW(pureSW(a).flatMap(f), f(a))
        }
    }

    @Test func rightIdentity() {
        for m in ms {
            expectSameSW(m.flatMap(pureSW), m)
        }
    }

    @Test func associativity() {
        let f = f
        let g = g
        for m in ms {
            expectSameSW(m.flatMap(f).flatMap(g), m.flatMap { a in f(a).flatMap(g) })
        }
    }

    @Test func applicativeEqualsAp() {
        let sf: BindLawSW<@Sendable (Int) -> Int> = stepSW { s in
            s += 100
            return Writer({ $0 * 2 }, ["fn"])
        }
        let sb: BindLawSW<String> = stepSW { s in
            s *= 3
            return Writer("b\(s)", ["rhs"])
        }
        for sa in ms {
            expectSameSW(BindLawSW<Int>.apply(sf, sa), sf.flatMap { fn in sa.map(fn) })
            expectSameSW(
                BindLawSW<String>.liftA2 { (a: Int, b: String) in "\(a)\(b)" }(sa, sb),
                sa.flatMap { a in sb.map { b in "\(a)\(b)" } }
            )
            expectSameSW(sa.seqRight(sb), sa.flatMap(const(sb)))
            expectSameSW(sa.seqLeft(sb), sa.flatMap { a in sb.map(const(a)) })
        }
    }

    @Test func continuationTouchesStateAndLogs() {
        let m: BindLawSW<Int> = stepSW { s in
            s += 1
            return Writer(s, ["start"])
        }
        let result = m.flatMap { a in
            stepSW { s in
                s *= 10
                return Writer("\(a)", ["state was \(s / 10)"])
            }
        }
        let (writer, finalState) = result.rawValue.runStateful(4)
        #expect(writer == Writer("5", ["start", "state was 5"]))
        #expect(finalState == 50)
    }

    @Test func bindAndKleisliAgreeWithFlatMap() {
        for m in ms {
            expectSameSW(BindLawSW<Int>.bind(f)(m), m.flatMap(f))
        }
        for a in [0, 2] {
            expectSameSW(BindLawSW<Int>.kleisli(f, g)(a), f(a).flatMap(g))
        }
    }
}

// MARK: - ReaderTNonEmpty

typealias BindLawRN<A> = Reader<Int, NonEmpty<A>>
typealias StackRN<A> = ReaderTNonEmpty<Int, A>

private func pureRN<A: Sendable>(_ value: A) -> StackRN<A> {
    StackRN<A>.pure(value)
}

private func expectSameRN<A: Equatable & Sendable>(
    _ actual: StackRN<A>,
    _ expected: StackRN<A>,
    sourceLocation: SourceLocation = #_sourceLocation
) {
    for env in environments {
        #expect(actual.rawValue(env) == expected.rawValue(env), sourceLocation: sourceLocation)
    }
}

@Suite struct ReaderTNonEmptyBindLawTests {
    let ms: [StackRN<Int>] = [
        StackRN(BindLawRN { env in NonEmpty(head: env, tail: [env + 1]) }),
        StackRN(BindLawRN { env in NonEmpty(head: env * 10) })
    ]
    let f: @Sendable (Int) -> StackRN<Int> = { a in StackRN(BindLawRN { env in NonEmpty(head: a, tail: [a + env]) }) }
    let g: @Sendable (Int) -> StackRN<String> = { b in StackRN(BindLawRN { env in NonEmpty(head: "\(b)", tail: ["\(b * env)"]) }) }

    @Test func leftIdentity() {
        for a in [0, 1, 7] {
            expectSameRN(pureRN(a).flatMap(f), f(a))
        }
    }

    @Test func rightIdentity() {
        for m in ms {
            expectSameRN(m.flatMap(pureRN), m)
        }
    }

    @Test func associativity() {
        let f = f
        let g = g
        for m in ms {
            expectSameRN(m.flatMap(f).flatMap(g), m.flatMap { a in f(a).flatMap(g) })
        }
    }

    @Test func applicativeEqualsAp() {
        let rf = StackRN(BindLawRN<@Sendable (Int) -> Int> { env in NonEmpty(head: { $0 + env }, tail: [{ $0 * 2 }]) })
        let rb = StackRN(BindLawRN<String> { env in NonEmpty(head: "x\(env)", tail: ["y"]) })
        for ra in ms {
            expectSameRN(StackRN<Int>.apply(rf, ra), rf.flatMap { fn in ra.map(fn) })
            expectSameRN(
                StackRN<String>.liftA2 { (a: Int, b: String) in "\(a)\(b)" }(ra, rb),
                ra.flatMap { a in rb.map { b in "\(a)\(b)" } }
            )
            expectSameRN(ra.seqRight(rb), ra.flatMap(const(rb)))
            expectSameRN(ra.seqLeft(rb), ra.flatMap { a in rb.map(const(a)) })
        }
    }

    @Test func continuationReadsEnvironment() {
        let m = StackRN(BindLawRN<Int>(const(NonEmpty(head: 1, tail: [2]))))
        let result = m.flatMap { a in StackRN(BindLawRN<String> { env in NonEmpty(head: "\(a)", tail: ["\(a)@\(env)"]) }) }
        #expect(result.rawValue(9) == NonEmpty(head: "1", tail: ["1@9", "2", "2@9"]))
    }

    @Test func bindAndKleisliAgreeWithFlatMap() {
        for m in ms {
            expectSameRN(StackRN<Int>.bind(f)(m), m.flatMap(f))
        }
        for a in [0, 2] {
            expectSameRN(StackRN<Int>.kleisli(f, g)(a), f(a).flatMap(g))
        }
    }
}
