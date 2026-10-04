// SPDX-License-Identifier: Apache-2.0
import CoreFP
import DataStructure
import Testing

// `<*> = ap` law for the Either/Optional-outer, Optional/Result/Either-inner stacks:
// apply, liftA2, seqRight and seqLeft must agree with their definitions via `flatMapT` + `mapT`
// for every combination of outer and inner cases.

private enum StackError: Error, Equatable {
    case fromFunction
    case fromValue
}

@Suite struct EitherOptionalStacksApLawTests {
    // MARK: - EitherTOptional (Haskell: MaybeT (Either L))

    private static let eitherOptionalFns: [Either<String, (@Sendable (Int) -> Int)?>] = [
        .left("f"),
        .right(nil),
        .right { $0 + 1 },
        .right { $0 * 10 }
    ]
    private static let eitherOptionalXs: [Either<String, Int?>] = [.left("x"), .right(nil), .right(2)]
    private static let eitherOptionalYs: [Either<String, Int?>] = [.left("y"), .right(nil), .right(5)]

    @Test func eitherTOptionalApplyIsAp() {
        for fns in Self.eitherOptionalFns {
            for values in Self.eitherOptionalYs {
                let viaBind = flatMapTEitherOptional(fns) { fn in values.mapT(fn) }
                #expect(applyEitherOptional(fns, values) == viaBind)
            }
        }
    }

    @Test func eitherTOptionalLiftA2IsBind() {
        let lifted: (Either<String, Int?>, Either<String, Int?>) -> Either<String, Int?> =
            liftA2EitherOptional { a, b in a * 100 + b }
        for lhs in Self.eitherOptionalXs {
            for rhs in Self.eitherOptionalYs {
                let viaBind = flatMapTEitherOptional(lhs) { a in rhs.mapT { b in a * 100 + b } }
                #expect(lifted(lhs, rhs) == viaBind)
            }
        }
    }

    @Test func eitherTOptionalSeqRightSeqLeftAreBind() {
        for lhs in Self.eitherOptionalXs {
            for rhs in Self.eitherOptionalYs {
                #expect(seqRightEitherOptional(lhs, rhs) == flatMapTEitherOptional(lhs, const(rhs)))
                let seqLeftViaBind = flatMapTEitherOptional(lhs) { a in rhs.mapT(const(a)) }
                #expect(seqLeftEitherOptional(lhs, rhs) == seqLeftViaBind)
            }
        }
    }

    @Test func eitherTOptionalNoneBeforeLeftShortCircuits() {
        let fns: Either<String, (@Sendable (Int) -> Int)?> = .right(nil)
        let values: Either<String, Int?> = .left("l")
        #expect(applyEitherOptional(fns, values) == .right(nil))
    }

    // MARK: - EitherTResult (Haskell: ExceptT E (Either L))

    private static let eitherResultFns: [Either<String, Result<@Sendable (Int) -> Int, StackError>>] = [
        .left("f"),
        .right(.failure(.fromFunction)),
        .right(.success { $0 + 1 }),
        .right(.success { $0 * 10 })
    ]
    private static let eitherResultXs: [Either<String, Result<Int, StackError>>] = [
        .left("x"),
        .right(.failure(.fromFunction)),
        .right(.success(2))
    ]
    private static let eitherResultYs: [Either<String, Result<Int, StackError>>] = [
        .left("y"),
        .right(.failure(.fromValue)),
        .right(.success(5))
    ]

    @Test func eitherTResultApplyIsAp() {
        for fns in Self.eitherResultFns {
            for values in Self.eitherResultYs {
                let viaBind = flatMapTEitherResult(fns) { fn in values.mapT(fn) }
                #expect(applyEitherResult(fns, values) == viaBind)
            }
        }
    }

    @Test func eitherTResultLiftA2IsBind() {
        let lifted: (Either<String, Result<Int, StackError>>, Either<String, Result<Int, StackError>>)
            -> Either<String, Result<Int, StackError>> = liftA2EitherResult { a, b in a * 100 + b }
        for lhs in Self.eitherResultXs {
            for rhs in Self.eitherResultYs {
                let viaBind = flatMapTEitherResult(lhs) { a in rhs.mapT { b in a * 100 + b } }
                #expect(lifted(lhs, rhs) == viaBind)
            }
        }
    }

    @Test func eitherTResultSeqRightSeqLeftAreBind() {
        for lhs in Self.eitherResultXs {
            for rhs in Self.eitherResultYs {
                #expect(seqRightEitherResult(lhs, rhs) == flatMapTEitherResult(lhs, const(rhs)))
                let seqLeftViaBind = flatMapTEitherResult(lhs) { a in rhs.mapT(const(a)) }
                #expect(seqLeftEitherResult(lhs, rhs) == seqLeftViaBind)
            }
        }
    }

    @Test func eitherTResultFailureBeforeLeftShortCircuits() {
        let fns: Either<String, Result<@Sendable (Int) -> Int, StackError>> = .right(.failure(.fromFunction))
        let values: Either<String, Result<Int, StackError>> = .left("l")
        #expect(applyEitherResult(fns, values) == .right(.failure(.fromFunction)))
    }

    // MARK: - OptionalTEither (Haskell: ExceptT L Maybe)

    private static let optionalEitherFns: [Either<String, @Sendable (Int) -> Int>?] = [
        nil,
        .some(.left("f")),
        .some(.right { $0 + 1 }),
        .some(.right { $0 * 10 })
    ]
    private static let optionalEitherXs: [Either<String, Int>?] = [nil, .some(.left("x")), .some(.right(2))]
    private static let optionalEitherYs: [Either<String, Int>?] = [nil, .some(.left("y")), .some(.right(5))]

    @Test func optionalTEitherApplyIsAp() {
        for fns in Self.optionalEitherFns {
            for values in Self.optionalEitherYs {
                let viaBind = fns.flatMapT { fn in values.mapT(fn) }
                #expect(applyOptionalEither(fns, values) == viaBind)
            }
        }
    }

    @Test func optionalTEitherLiftA2IsBind() {
        let lifted: (Either<String, Int>?, Either<String, Int>?) -> Either<String, Int>? =
            liftA2OptionalEither { a, b in a * 100 + b }
        for lhs in Self.optionalEitherXs {
            for rhs in Self.optionalEitherYs {
                let viaBind = lhs.flatMapT { a in rhs.mapT { b in a * 100 + b } }
                #expect(lifted(lhs, rhs) == viaBind)
            }
        }
    }

    @Test func optionalTEitherSeqRightSeqLeftAreBind() {
        for lhs in Self.optionalEitherXs {
            for rhs in Self.optionalEitherYs {
                #expect(seqRightOptionalEither(lhs, rhs) == lhs.flatMapT(const(rhs)))
                #expect(seqLeftOptionalEither(lhs, rhs) == lhs.flatMapT { a in rhs.mapT(const(a)) })
            }
        }
    }

    @Test func optionalTEitherLeftBeforeNoneShortCircuits() {
        let fns: Either<String, @Sendable (Int) -> Int>? = .some(.left("l"))
        let values: Either<String, Int>? = nil
        #expect(applyOptionalEither(fns, values) == .some(.left("l")))
    }
}
