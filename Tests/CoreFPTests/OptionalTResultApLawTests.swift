// SPDX-License-Identifier: Apache-2.0
import CoreFP
import Testing

// `<*> = ap` law for OptionalTResult (Haskell: ExceptT E Maybe): apply, liftA2, seqRight and
// seqLeft must agree with their definitions via `flatMapT` + `mapT` for every case combination.

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
                let viaBind = fns.flatMapT { fn in values.mapT(fn) }
                #expect(applyOptionalResult(fns, values) == viaBind)
            }
        }
    }

    @Test func liftA2IsBind() {
        let lifted: (Result<Int, StackError>?, Result<Int, StackError>?) -> Result<Int, StackError>? =
            liftA2OptionalResult { a, b in a * 100 + b }
        for lhs in Self.lhsStacks {
            for rhs in Self.rhsStacks {
                let viaBind = lhs.flatMapT { a in rhs.mapT { b in a * 100 + b } }
                #expect(lifted(lhs, rhs) == viaBind)
            }
        }
    }

    @Test func seqRightSeqLeftAreBind() {
        for lhs in Self.lhsStacks {
            for rhs in Self.rhsStacks {
                #expect(seqRightOptionalResult(lhs, rhs) == lhs.flatMapT(const(rhs)))
                #expect(seqLeftOptionalResult(lhs, rhs) == lhs.flatMapT { a in rhs.mapT(const(a)) })
            }
        }
    }

    @Test func failureBeforeNoneShortCircuits() {
        let fns: Result<@Sendable (Int) -> Int, StackError>? = .some(.failure(.fromFunction))
        let values: Result<Int, StackError>? = nil
        let lhs: Result<Int, StackError>? = .some(.failure(.fromLhs))
        #expect(applyOptionalResult(fns, values) == .some(.failure(.fromFunction)))
        #expect(seqRightOptionalResult(lhs, values) == .some(.failure(.fromLhs)))
    }
}
