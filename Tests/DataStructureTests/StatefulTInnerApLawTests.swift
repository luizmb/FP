// SPDX-License-Identifier: Apache-2.0
import CoreFP
import DataStructure
import Testing

// `<*>` must equal `ap` (`mf >>= \f -> fmap f ma`) for `Stateful<S, Either/Optional/Result>`, mirroring
// Haskell's `ExceptT e (State s)` / `MaybeT (State s)`: once the inner layer fails, the right-hand state
// effect must not run, while state updates made before the failure are kept.

enum StatefulApError: Error, Equatable {
    case function
    case lhs
    case rhs
}

private let initialStates = [0, 3, -2]

/// A `Stateful` that first updates the state, then produces `output`.
private func step<A: Sendable>(_ update: @escaping @Sendable (Int) -> Int, _ output: A) -> Stateful<Int, A> {
    Stateful<Int, A> { s in
        s = update(s)
        return output
    }
}

private func expectSameRun<A: Equatable>(
    _ actual: Stateful<Int, A>,
    _ expected: Stateful<Int, A>,
    sourceLocation: SourceLocation = #_sourceLocation
) {
    for initial in initialStates {
        let (actualValue, actualState) = actual.runStateful(initial)
        let (expectedValue, expectedState) = expected.runStateful(initial)
        #expect(actualValue == expectedValue, sourceLocation: sourceLocation)
        #expect(actualState == expectedState, sourceLocation: sourceLocation)
    }
}

@Suite struct StatefulTEitherApLawTests {
    let functions: [Stateful<Int, Either<String, @Sendable (Int) -> Int>>] = [
        step({ $0 * 2 + 1 }, .right { $0 + 100 }),
        step({ $0 + 5 }, .left("f"))
    ]
    let lhs: [Stateful<Int, Either<String, Int>>] = [
        step({ $0 * 10 }, .right(10)),
        step({ $0 - 3 }, .left("a"))
    ]
    let rhs: [Stateful<Int, Either<String, String>>] = [
        step({ $0 * 7 }, .right("b")),
        step({ $0 + 11 }, .left("b"))
    ]

    @Test func applyEqualsAp() {
        for sf in functions {
            for sa in lhs {
                expectSameRun(
                    StatefulTEither.apply(sf.statefulT, sa.statefulT).rawValue,
                    sf.statefulT.flatMap { f in sa.statefulT.map(f) }.rawValue
                )
            }
        }
    }

    @Test func liftA2EqualsBind() {
        let combine: @Sendable (Int, String) -> String = { "\($0)-\($1)" }
        for sa in lhs {
            for sb in rhs {
                expectSameRun(
                    StatefulTEither.liftA2(combine)(sa.statefulT, sb.statefulT).rawValue,
                    sa.statefulT.flatMap { a in sb.statefulT.map { b in combine(a, b) } }.rawValue
                )
            }
        }
    }

    @Test func seqRightEqualsBind() {
        for sa in lhs {
            for sb in rhs {
                expectSameRun(sa.statefulT.seqRight(sb.statefulT).rawValue, sa.statefulT.flatMap(const(sb.statefulT)).rawValue)
            }
        }
    }

    @Test func seqLeftEqualsBind() {
        for sa in lhs {
            for sb in rhs {
                expectSameRun(
                    sa.statefulT.seqLeft(sb.statefulT).rawValue,
                    sa.statefulT.flatMap { a in sb.statefulT.map(const(a)) }.rawValue
                )
            }
        }
    }

    @Test func leftFunctionSkipsRightStateEffect() {
        let sf: Stateful<Int, Either<String, @Sendable (Int) -> Int>> = step({ $0 + 1 }, .left("e"))
        let sa: Stateful<Int, Either<String, Int>> = step({ $0 + 10 }, .right(1))
        let (value, state) = StatefulTEither.apply(sf.statefulT, sa.statefulT).rawValue.runStateful(0)
        #expect(value == .left("e"))
        #expect(state == 1)
    }
}

@Suite struct StatefulTOptionalApLawTests {
    let functions: [Stateful<Int, (@Sendable (Int) -> Int)?>] = [
        step({ $0 * 2 + 1 }, .some { $0 + 100 }),
        step({ $0 + 5 }, nil)
    ]
    let lhs: [Stateful<Int, Int?>] = [
        step({ $0 * 10 }, .some(10)),
        step({ $0 - 3 }, nil)
    ]
    let rhs: [Stateful<Int, String?>] = [
        step({ $0 * 7 }, .some("b")),
        step({ $0 + 11 }, nil)
    ]

    @Test func applyEqualsAp() {
        for sf in functions {
            for sa in lhs {
                expectSameRun(
                    StatefulTOptional.apply(sf.statefulT, sa.statefulT).rawValue,
                    sf.statefulT.flatMap { f in sa.statefulT.map(f) }.rawValue
                )
            }
        }
    }

    @Test func liftA2EqualsBind() {
        let combine: @Sendable (Int, String) -> String = { "\($0)-\($1)" }
        for sa in lhs {
            for sb in rhs {
                expectSameRun(
                    StatefulTOptional.liftA2(combine)(sa.statefulT, sb.statefulT).rawValue,
                    sa.statefulT.flatMap { a in sb.statefulT.map { b in combine(a, b) } }.rawValue
                )
            }
        }
    }

    @Test func seqRightEqualsBind() {
        for sa in lhs {
            for sb in rhs {
                expectSameRun(sa.statefulT.seqRight(sb.statefulT).rawValue, sa.statefulT.flatMap(const(sb.statefulT)).rawValue)
            }
        }
    }

    @Test func seqLeftEqualsBind() {
        for sa in lhs {
            for sb in rhs {
                expectSameRun(
                    sa.statefulT.seqLeft(sb.statefulT).rawValue,
                    sa.statefulT.flatMap { a in sb.statefulT.map(const(a)) }.rawValue
                )
            }
        }
    }

    @Test func noneSkipsRightStateEffectInEverySequencingFunction() {
        let none: Stateful<Int, Int?> = step({ $0 + 1 }, nil)
        let some: Stateful<Int, String?> = step({ $0 + 10 }, .some("x"))
        #expect(none.statefulT.seqRight(some.statefulT).rawValue.runStateful(0) == (nil, 1))
        #expect(none.statefulT.seqLeft(some.statefulT).rawValue.runStateful(0) == (nil, 1))
    }
}

@Suite struct StatefulTResultApLawTests {
    let functions: [Stateful<Int, Result<@Sendable (Int) -> Int, StatefulApError>>] = [
        step({ $0 * 2 + 1 }, .success { $0 + 100 }),
        step({ $0 + 5 }, .failure(.function))
    ]
    let lhs: [Stateful<Int, Result<Int, StatefulApError>>] = [
        step({ $0 * 10 }, .success(10)),
        step({ $0 - 3 }, .failure(.lhs))
    ]
    let rhs: [Stateful<Int, Result<String, StatefulApError>>] = [
        step({ $0 * 7 }, .success("b")),
        step({ $0 + 11 }, .failure(.rhs))
    ]

    @Test func applyEqualsAp() {
        for sf in functions {
            for sa in lhs {
                expectSameRun(
                    StatefulTResult.apply(sf.statefulT, sa.statefulT).rawValue,
                    sf.statefulT.flatMap { f in sa.statefulT.map(f) }.rawValue
                )
            }
        }
    }

    @Test func liftA2EqualsBind() {
        let combine: @Sendable (Int, String) -> String = { "\($0)-\($1)" }
        for sa in lhs {
            for sb in rhs {
                expectSameRun(
                    StatefulTResult.liftA2(combine)(sa.statefulT, sb.statefulT).rawValue,
                    sa.statefulT.flatMap { a in sb.statefulT.map { b in combine(a, b) } }.rawValue
                )
            }
        }
    }

    @Test func seqRightEqualsBind() {
        for sa in lhs {
            for sb in rhs {
                expectSameRun(sa.statefulT.seqRight(sb.statefulT).rawValue, sa.statefulT.flatMap(const(sb.statefulT)).rawValue)
            }
        }
    }

    @Test func seqLeftEqualsBind() {
        for sa in lhs {
            for sb in rhs {
                expectSameRun(
                    sa.statefulT.seqLeft(sb.statefulT).rawValue,
                    sa.statefulT.flatMap { a in sb.statefulT.map(const(a)) }.rawValue
                )
            }
        }
    }

    @Test func failedFunctionDoesNotRunRightHandSide() {
        let sf: Stateful<Int, Result<@Sendable (Int) -> Int, StatefulApError>> = step({ $0 + 1 }, .failure(.function))
        let sa: Stateful<Int, Result<Int, StatefulApError>> = step({ $0 + 10 }, .success(1))
        let (value, state) = StatefulTResult.apply(sf.statefulT, sa.statefulT).rawValue.runStateful(0)
        #expect(value == .failure(.function))
        #expect(state == 1)
    }
}
