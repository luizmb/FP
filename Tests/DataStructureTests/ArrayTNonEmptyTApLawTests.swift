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
                #expect(applyArrayEither(fns, values) == fns.flatMapT { f in values.mapT(f) })
            }
        }
    }

    @Test func liftA2EqualsBind() {
        for lhs in ints {
            for rhs in strings {
                let expected: [Either<String, String>] = lhs.flatMapT { n in rhs.mapT { s in combine(n, s) } }
                #expect(liftA2ArrayEither(combine)(lhs, rhs) == expected)
            }
        }
    }

    @Test func seqRightEqualsBind() {
        for lhs in ints {
            for rhs in strings {
                #expect(seqRightArrayEither(lhs, rhs) == lhs.flatMapT { (_: Int) in rhs })
            }
        }
    }

    @Test func seqLeftEqualsBind() {
        for lhs in ints {
            for rhs in strings {
                #expect(seqLeftArrayEither(lhs, rhs) == lhs.flatMapT { n in rhs.mapT { (_: String) in n } })
            }
        }
    }

    @Test func leftFunctionShortCircuits() {
        let fns: [Either<String, @Sendable (Int) -> Int>] = [.left("e")]
        #expect(applyArrayEither(fns, [.right(1), .right(2)]) == [.left("e")])
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
                #expect(applyNonEmptyEither(fns, values).toArray == fns.flatMapT { f in values.mapT(f) }.toArray)
            }
        }
    }

    @Test func liftA2EqualsBind() {
        for lhs in ints {
            for rhs in strings {
                let expected: NonEmpty<Either<String, String>> = lhs.flatMapT { n in rhs.mapT { s in combine(n, s) } }
                #expect(liftA2NonEmptyEither(combine)(lhs, rhs).toArray == expected.toArray)
            }
        }
    }

    @Test func seqRightEqualsBind() {
        for lhs in ints {
            for rhs in strings {
                #expect(seqRightNonEmptyEither(lhs, rhs).toArray == lhs.flatMapT { (_: Int) in rhs }.toArray)
            }
        }
    }

    @Test func seqLeftEqualsBind() {
        for lhs in ints {
            for rhs in strings {
                let expected = lhs.flatMapT { n in rhs.mapT { (_: String) in n } }
                #expect(seqLeftNonEmptyEither(lhs, rhs).toArray == expected.toArray)
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
                #expect(applyNonEmptyOptional(fns, values).toArray == fns.flatMapT { f in values.mapT(f) }.toArray)
            }
        }
    }

    @Test func liftA2EqualsBind() {
        for lhs in ints {
            for rhs in strings {
                let expected: NonEmpty<String?> = lhs.flatMapT { n in rhs.mapT { s in combine(n, s) } }
                #expect(liftA2NonEmptyOptional(combine)(lhs, rhs).toArray == expected.toArray)
            }
        }
    }

    @Test func seqRightEqualsBind() {
        for lhs in ints {
            for rhs in strings {
                #expect(seqRightNonEmptyOptional(lhs, rhs).toArray == lhs.flatMapT { (_: Int) in rhs }.toArray)
            }
        }
    }

    @Test func seqLeftEqualsBind() {
        for lhs in ints {
            for rhs in strings {
                let expected = lhs.flatMapT { n in rhs.mapT { (_: String) in n } }
                #expect(seqLeftNonEmptyOptional(lhs, rhs).toArray == expected.toArray)
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
                #expect(applyNonEmptyResult(fns, values).toArray == fns.flatMapT { f in values.mapT(f) }.toArray)
            }
        }
    }

    @Test func liftA2EqualsBind() {
        for lhs in ints {
            for rhs in strings {
                let expected: NonEmpty<Result<String, ApLawError>> = lhs.flatMapT { n in rhs.mapT { s in combine(n, s) } }
                #expect(liftA2NonEmptyResult(combine)(lhs, rhs).toArray == expected.toArray)
            }
        }
    }

    @Test func seqRightEqualsBind() {
        for lhs in ints {
            for rhs in strings {
                #expect(seqRightNonEmptyResult(lhs, rhs).toArray == lhs.flatMapT { (_: Int) in rhs }.toArray)
            }
        }
    }

    @Test func seqLeftEqualsBind() {
        for lhs in ints {
            for rhs in strings {
                let expected = lhs.flatMapT { n in rhs.mapT { (_: String) in n } }
                #expect(seqLeftNonEmptyResult(lhs, rhs).toArray == expected.toArray)
            }
        }
    }
}
