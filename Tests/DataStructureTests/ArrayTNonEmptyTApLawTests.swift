// SPDX-License-Identifier: Apache-2.0
import CoreFP
import DataStructure
import Testing

// `<*> = ap` for the lawful Array/NonEmpty-outer stacks (Haskell `ExceptT l []`,
// `MaybeT NonEmpty`, `ExceptT e NonEmpty`): apply / liftA2 / seqRight / seqLeft must agree
// with their bind definitions for every pair of representative values covering every inner case.

private enum ApLawError: Error, Equatable {
    case first
    case second
}

private let combine: @Sendable (Int, String) -> String = { n, s in "\(n)\(s)" }

@Suite struct ArrayTEitherApLawTests {
    private let functions: [[Either<String, @Sendable (Int) -> Int>]] = [
        [],
        [.left("f")],
        [.right { $0 + 1 }],
        [.right { $0 + 1 }, .left("f"), .right { $0 * 10 }],
        [.left("g"), .right { $0 - 3 }]
    ]
    private let ints: [[Either<String, Int>]] = [
        [],
        [.left("a")],
        [.right(1)],
        [.right(1), .left("a"), .right(2)],
        [.left("b"), .right(5)]
    ]
    private let strings: [[Either<String, String>]] = [
        [],
        [.left("s")],
        [.right("x")],
        [.right("x"), .left("s"), .right("y")],
        [.left("t"), .right("z")]
    ]

    @Test func applyEqualsAp() {
        for fns in functions {
            for values in ints {
                #expect(ArrayTEither.apply(fns.arrayT, values.arrayT).rawValue == fns.arrayT.flatMap { f in values.arrayT.map(f) }.rawValue)
            }
        }
    }

    @Test func liftA2EqualsBind() {
        for lhs in ints {
            for rhs in strings {
                let expected: [Either<String, String>] = lhs.arrayT.flatMap { n in rhs.arrayT.map { s in combine(n, s) } }.rawValue
                #expect(ArrayTEither.liftA2(combine)(lhs.arrayT, rhs.arrayT).rawValue == expected)
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

    @Test func leftFunctionShortCircuits() {
        let fns: [Either<String, @Sendable (Int) -> Int>] = [.left("e")]
        #expect(ArrayTEither.apply(fns.arrayT, ArrayTEither<String, Int>([.right(1), .right(2)])).rawValue == [.left("e")])
    }
}

@Suite struct NonEmptyTEitherApLawTests {
    private let functions: [NonEmpty<Either<String, @Sendable (Int) -> Int>>] = [
        NonEmpty(head: .left("f")),
        NonEmpty(head: .right { $0 + 1 }),
        NonEmpty(head: .right { $0 + 1 }, tail: [.left("f"), .right { $0 * 10 }]),
        NonEmpty(head: .left("g"), tail: [.right { $0 - 3 }])
    ]
    private let ints: [NonEmpty<Either<String, Int>>] = [
        NonEmpty(head: .left("a")),
        NonEmpty(head: .right(1)),
        NonEmpty(head: .right(1), tail: [.left("a"), .right(2)]),
        NonEmpty(head: .left("b"), tail: [.right(5)])
    ]
    private let strings: [NonEmpty<Either<String, String>>] = [
        NonEmpty(head: .left("s")),
        NonEmpty(head: .right("x")),
        NonEmpty(head: .right("x"), tail: [.left("s"), .right("y")]),
        NonEmpty(head: .left("t"), tail: [.right("z")])
    ]

    @Test func applyEqualsAp() {
        for fns in functions {
            for values in ints {
                #expect(NonEmptyTEither.apply(fns.nonEmptyT, values.nonEmptyT).rawValue.toArray == fns.nonEmptyT.flatMap { f in
                    values.nonEmptyT.map(f)
                }.rawValue.toArray)
            }
        }
    }

    @Test func liftA2EqualsBind() {
        for lhs in ints {
            for rhs in strings {
                let expected: NonEmpty<Either<String, String>> = lhs.nonEmptyT
                    .flatMap { n in rhs.nonEmptyT.map { s in combine(n, s) } }
                    .rawValue
                #expect(NonEmptyTEither.liftA2(combine)(lhs.nonEmptyT, rhs.nonEmptyT).rawValue.toArray == expected.toArray)
            }
        }
    }

    @Test func seqRightEqualsBind() {
        for lhs in ints {
            for rhs in strings {
                #expect(lhs.nonEmptyT.seqRight(rhs.nonEmptyT).rawValue.toArray == lhs.nonEmptyT.flatMap { (_: Int) in
                    rhs.nonEmptyT
                }.rawValue.toArray)
            }
        }
    }

    @Test func seqLeftEqualsBind() {
        for lhs in ints {
            for rhs in strings {
                let expected = lhs.nonEmptyT.flatMap { n in rhs.nonEmptyT.map { (_: String) in n } }.rawValue
                #expect(lhs.nonEmptyT.seqLeft(rhs.nonEmptyT).rawValue.toArray == expected.toArray)
            }
        }
    }
}

@Suite struct NonEmptyTOptionalApLawTests {
    private let functions: [NonEmpty<(@Sendable (Int) -> Int)?>] = [
        NonEmpty(head: nil),
        NonEmpty(head: { $0 + 1 }),
        NonEmpty(head: { $0 + 1 }, tail: [nil, { $0 * 10 }]),
        NonEmpty(head: nil, tail: [{ $0 - 3 }])
    ]
    private let ints: [NonEmpty<Int?>] = [
        NonEmpty(head: nil),
        NonEmpty(head: 1),
        NonEmpty(head: 1, tail: [nil, 2]),
        NonEmpty(head: nil, tail: [5])
    ]
    private let strings: [NonEmpty<String?>] = [
        NonEmpty(head: nil),
        NonEmpty(head: "x"),
        NonEmpty(head: "x", tail: [nil, "y"]),
        NonEmpty(head: nil, tail: ["z"])
    ]

    @Test func applyEqualsAp() {
        for fns in functions {
            for values in ints {
                #expect(NonEmptyTOptional.apply(fns.nonEmptyT, values.nonEmptyT).rawValue.toArray == fns.nonEmptyT.flatMap { f in
                    values.nonEmptyT.map(f)
                }.rawValue.toArray)
            }
        }
    }

    @Test func liftA2EqualsBind() {
        for lhs in ints {
            for rhs in strings {
                let expected: NonEmpty<String?> = lhs.nonEmptyT.flatMap { n in rhs.nonEmptyT.map { s in combine(n, s) } }.rawValue
                #expect(NonEmptyTOptional.liftA2(combine)(lhs.nonEmptyT, rhs.nonEmptyT).rawValue.toArray == expected.toArray)
            }
        }
    }

    @Test func seqRightEqualsBind() {
        for lhs in ints {
            for rhs in strings {
                #expect(lhs.nonEmptyT.seqRight(rhs.nonEmptyT).rawValue.toArray == lhs.nonEmptyT.flatMap { (_: Int) in
                    rhs.nonEmptyT
                }.rawValue.toArray)
            }
        }
    }

    @Test func seqLeftEqualsBind() {
        for lhs in ints {
            for rhs in strings {
                let expected = lhs.nonEmptyT.flatMap { n in rhs.nonEmptyT.map { (_: String) in n } }.rawValue
                #expect(lhs.nonEmptyT.seqLeft(rhs.nonEmptyT).rawValue.toArray == expected.toArray)
            }
        }
    }
}

@Suite struct NonEmptyTResultApLawTests {
    private let functions: [NonEmpty<Result<@Sendable (Int) -> Int, ApLawError>>] = [
        NonEmpty(head: .failure(.first)),
        NonEmpty(head: .success { $0 + 1 }),
        NonEmpty(head: .success { $0 + 1 }, tail: [.failure(.first), .success { $0 * 10 }]),
        NonEmpty(head: .failure(.second), tail: [.success { $0 - 3 }])
    ]
    private let ints: [NonEmpty<Result<Int, ApLawError>>] = [
        NonEmpty(head: .failure(.second)),
        NonEmpty(head: .success(1)),
        NonEmpty(head: .success(1), tail: [.failure(.second), .success(2)]),
        NonEmpty(head: .failure(.first), tail: [.success(5)])
    ]
    private let strings: [NonEmpty<Result<String, ApLawError>>] = [
        NonEmpty(head: .failure(.second)),
        NonEmpty(head: .success("x")),
        NonEmpty(head: .success("x"), tail: [.failure(.second), .success("y")]),
        NonEmpty(head: .failure(.first), tail: [.success("z")])
    ]

    @Test func applyEqualsAp() {
        for fns in functions {
            for values in ints {
                #expect(NonEmptyTResult.apply(fns.nonEmptyT, values.nonEmptyT).rawValue.toArray == fns.nonEmptyT.flatMap { f in
                    values.nonEmptyT.map(f)
                }.rawValue.toArray)
            }
        }
    }

    @Test func liftA2EqualsBind() {
        for lhs in ints {
            for rhs in strings {
                let expected: NonEmpty<Result<String, ApLawError>> = lhs.nonEmptyT
                    .flatMap { n in rhs.nonEmptyT.map { s in combine(n, s) } }
                    .rawValue
                #expect(NonEmptyTResult.liftA2(combine)(lhs.nonEmptyT, rhs.nonEmptyT).rawValue.toArray == expected.toArray)
            }
        }
    }

    @Test func seqRightEqualsBind() {
        for lhs in ints {
            for rhs in strings {
                #expect(lhs.nonEmptyT.seqRight(rhs.nonEmptyT).rawValue.toArray == lhs.nonEmptyT.flatMap { (_: Int) in
                    rhs.nonEmptyT
                }.rawValue.toArray)
            }
        }
    }

    @Test func seqLeftEqualsBind() {
        for lhs in ints {
            for rhs in strings {
                let expected = lhs.nonEmptyT.flatMap { n in rhs.nonEmptyT.map { (_: String) in n } }.rawValue
                #expect(lhs.nonEmptyT.seqLeft(rhs.nonEmptyT).rawValue.toArray == expected.toArray)
            }
        }
    }
}
