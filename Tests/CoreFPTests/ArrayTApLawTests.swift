// SPDX-License-Identifier: Apache-2.0
import CoreFP
import Testing

// `<*> = ap` for the lawful Array-outer stacks (Haskell `MaybeT []`, `ExceptT e []`):
// apply / liftA2 / seqRight / seqLeft must agree with their bind definitions for every pair
// of representative values, including empty outers and every inner case.

private enum ApLawError: Error, Equatable {
    case first
    case second
}

private let combine: @Sendable (Int, String) -> String = { n, s in "\(n)\(s)" }

@Suite struct ArrayTOptionalApLawTests {
    private let functions: [[(@Sendable (Int) -> Int)?]] = [
        [],
        [nil],
        [{ $0 + 1 }],
        [{ $0 + 1 }, nil, { $0 * 10 }],
        [nil, { $0 - 3 }]
    ]
    private let ints: [[Int?]] = [[], [nil], [1], [1, nil, 2], [nil, 5]]
    private let strings: [[String?]] = [[], [nil], ["x"], ["x", nil, "y"], [nil, "z"]]

    @Test func applyEqualsAp() {
        for fns in functions {
            for values in ints {
                #expect(ArrayTOptional.apply(ArrayTOptional(fns), ArrayTOptional(values)).rawValue == fns.arrayT.flatMap { f in
                    values.arrayT.map(f)
                }.rawValue)
            }
        }
    }

    @Test func liftA2EqualsBind() {
        for lhs in ints {
            for rhs in strings {
                let expected: [String?] = lhs.arrayT.flatMap { n in rhs.arrayT.map { s in combine(n, s) } }.rawValue
                #expect(ArrayTOptional.liftA2(combine)(lhs.arrayT, rhs.arrayT).rawValue == expected)
            }
        }
    }

    @Test func seqRightEqualsBind() {
        for lhs in ints {
            for rhs in strings {
                #expect(lhs.arrayT.seqRight(rhs.arrayT).rawValue == lhs.arrayT.flatMap { (_: Int) in rhs.arrayT }.rawValue)
            }
        }
    }

    @Test func seqLeftEqualsBind() {
        for lhs in ints {
            for rhs in strings {
                #expect(lhs.arrayT.seqLeft(rhs.arrayT).rawValue == lhs.arrayT.flatMap { n in rhs.arrayT.map { (_: String) in n } }.rawValue)
            }
        }
    }

    @Test func nilFunctionShortCircuits() {
        let fns: [(@Sendable (Int) -> Int)?] = [nil]
        #expect(ArrayTOptional.apply(fns.arrayT, ArrayTOptional([1, 2])).rawValue == [nil])
    }
}

@Suite struct ArrayTResultApLawTests {
    private let functions: [[Result<@Sendable (Int) -> Int, ApLawError>]] = [
        [],
        [.failure(.first)],
        [.success { $0 + 1 }],
        [.success { $0 + 1 }, .failure(.first), .success { $0 * 10 }],
        [.failure(.second), .success { $0 - 3 }]
    ]
    private let ints: [[Result<Int, ApLawError>]] = [
        [],
        [.failure(.second)],
        [.success(1)],
        [.success(1), .failure(.second), .success(2)],
        [.failure(.first), .success(5)]
    ]
    private let strings: [[Result<String, ApLawError>]] = [
        [],
        [.failure(.second)],
        [.success("x")],
        [.success("x"), .failure(.second), .success("y")],
        [.failure(.first), .success("z")]
    ]

    @Test func applyEqualsAp() {
        for fns in functions {
            for values in ints {
                #expect(ArrayTResult.apply(ArrayTResult(fns), ArrayTResult(values)).rawValue == fns.arrayT.flatMap { f in
                    values.arrayT.map(f)
                }.rawValue)
            }
        }
    }

    @Test func liftA2EqualsBind() {
        for lhs in ints {
            for rhs in strings {
                let expected: [Result<String, ApLawError>] = lhs.arrayT.flatMap { n in rhs.arrayT.map { s in combine(n, s) } }.rawValue
                #expect(ArrayTResult.liftA2(combine)(lhs.arrayT, rhs.arrayT).rawValue == expected)
            }
        }
    }

    @Test func seqRightEqualsBind() {
        for lhs in ints {
            for rhs in strings {
                #expect(lhs.arrayT.seqRight(rhs.arrayT).rawValue == lhs.arrayT.flatMap { (_: Int) in rhs.arrayT }.rawValue)
            }
        }
    }

    @Test func seqLeftEqualsBind() {
        for lhs in ints {
            for rhs in strings {
                #expect(lhs.arrayT.seqLeft(rhs.arrayT).rawValue == lhs.arrayT.flatMap { n in rhs.arrayT.map { (_: String) in n } }.rawValue)
            }
        }
    }

    @Test func failureFunctionShortCircuits() {
        let fns: [Result<@Sendable (Int) -> Int, ApLawError>] = [.failure(.first)]
        #expect(ArrayTResult.apply(fns.arrayT, ArrayTResult([.success(1), .success(2)])).rawValue == [.failure(.first)])
    }
}
