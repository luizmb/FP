// SPDX-License-Identifier: Apache-2.0
import CoreFP
import Testing

// `<*> = ap` law for OptionalTResult (Haskell: ExceptT E Maybe): apply, liftA2, seqRight and
// seqLeft must agree with their definitions via `flatMap` + `map` for every case combination.

private enum StackError: Error, Equatable {
    case fromFunction
    case fromLhs
    case fromRhs
}

@Suite struct OptionalTResultApLawTests {
    private static let fnStacks: [Result<@Sendable (Int) -> Int, StackError>?] = [
        nil,
        .some(.failure(.fromFunction)),
        .some(.success { $0 + 1 }),
        .some(.success { $0 * 10 })
    ]
    private static let lhsStacks: [Result<Int, StackError>?] = [nil, .some(.failure(.fromLhs)), .some(.success(2))]
    private static let rhsStacks: [Result<Int, StackError>?] = [nil, .some(.failure(.fromRhs)), .some(.success(5))]

    @Test func applyIsAp() {
        for fns in Self.fnStacks {
            for values in Self.rhsStacks {
                let viaBind = fns.optionalT.flatMap { fn in values.optionalT.map(fn) }.rawValue
                #expect(OptionalTResult.apply(OptionalTResult(fns), OptionalTResult(values)).rawValue == viaBind)
            }
        }
    }

    @Test func liftA2IsBind() {
        let lifted: (OptionalTResult<StackError, Int>, OptionalTResult<StackError, Int>) -> OptionalTResult<StackError, Int> =
            OptionalTResult.liftA2 { a, b in a * 100 + b }
        for lhs in Self.lhsStacks {
            for rhs in Self.rhsStacks {
                let viaBind = lhs.optionalT.flatMap { a in rhs.optionalT.map { b in a * 100 + b } }.rawValue
                #expect(lifted(OptionalTResult(lhs), OptionalTResult(rhs)).rawValue == viaBind)
            }
        }
    }

    @Test func seqRightSeqLeftAreBind() {
        for lhs in Self.lhsStacks {
            for rhs in Self.rhsStacks {
                let lhsT = OptionalTResult(lhs)
                let rhsT = OptionalTResult(rhs)
                #expect(lhsT.seqRight(rhsT).rawValue == lhsT.flatMap(const(rhsT)).rawValue)
                #expect(lhsT.seqLeft(rhsT).rawValue == lhsT.flatMap { a in rhsT.map(const(a)) }.rawValue)
            }
        }
    }

    @Test func failureBeforeNoneShortCircuits() {
        let fns: Result<@Sendable (Int) -> Int, StackError>? = .some(.failure(.fromFunction))
        let values: Result<Int, StackError>? = nil
        let lhs: Result<Int, StackError>? = .some(.failure(.fromLhs))
        #expect(OptionalTResult.apply(OptionalTResult(fns), OptionalTResult(values)).rawValue == .some(.failure(.fromFunction)))
        #expect(OptionalTResult(lhs).seqRight(OptionalTResult(values)).rawValue == .some(.failure(.fromLhs)))
    }
}
