// SPDX-License-Identifier: Apache-2.0
import CoreFP
import DataStructure
import Testing

// `<*> = ap` law for the Either/Optional-outer, Optional/Result/Either-inner stacks:
// apply, liftA2, seqRight and seqLeft must agree with their definitions via `flatMap` + `map`
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
                let viaBind = fns.eitherT.flatMap { fn in values.eitherT.map(fn) }.rawValue
                #expect(EitherTOptional.apply(fns.eitherT, values.eitherT).rawValue == viaBind)
            }
        }
    }

    @Test func eitherTOptionalLiftA2IsBind() {
        let lifted = EitherTOptional<String, Int>.liftA2 { (a: Int, b: Int) in a * 100 + b }
        for lhs in Self.eitherOptionalXs {
            for rhs in Self.eitherOptionalYs {
                let viaBind = lhs.eitherT.flatMap { a in rhs.eitherT.map { b in a * 100 + b } }.rawValue
                #expect(lifted(lhs.eitherT, rhs.eitherT).rawValue == viaBind)
            }
        }
    }

    @Test func eitherTOptionalSeqRightSeqLeftAreBind() {
        for lhs in Self.eitherOptionalXs {
            for rhs in Self.eitherOptionalYs {
                #expect(lhs.eitherT.seqRight(rhs.eitherT).rawValue == lhs.eitherT.flatMap(const(rhs.eitherT)).rawValue)
                let seqLeftViaBind = lhs.eitherT.flatMap { a in rhs.eitherT.map(const(a)) }.rawValue
                #expect(lhs.eitherT.seqLeft(rhs.eitherT).rawValue == seqLeftViaBind)
            }
        }
    }

    @Test func eitherTOptionalNoneBeforeLeftShortCircuits() {
        let fns: Either<String, (@Sendable (Int) -> Int)?> = .right(nil)
        let values: Either<String, Int?> = .left("l")
        #expect(EitherTOptional.apply(fns.eitherT, values.eitherT).rawValue == .right(nil))
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
                let viaBind = fns.eitherT.flatMap { fn in values.eitherT.map(fn) }.rawValue
                #expect(EitherTResult.apply(fns.eitherT, values.eitherT).rawValue == viaBind)
            }
        }
    }

    @Test func eitherTResultLiftA2IsBind() {
        let lifted = EitherTResult<String, StackError, Int>.liftA2 { (a: Int, b: Int) in a * 100 + b }
        for lhs in Self.eitherResultXs {
            for rhs in Self.eitherResultYs {
                let viaBind = lhs.eitherT.flatMap { a in rhs.eitherT.map { b in a * 100 + b } }.rawValue
                #expect(lifted(lhs.eitherT, rhs.eitherT).rawValue == viaBind)
            }
        }
    }

    @Test func eitherTResultSeqRightSeqLeftAreBind() {
        for lhs in Self.eitherResultXs {
            for rhs in Self.eitherResultYs {
                #expect(lhs.eitherT.seqRight(rhs.eitherT).rawValue == lhs.eitherT.flatMap(const(rhs.eitherT)).rawValue)
                let seqLeftViaBind = lhs.eitherT.flatMap { a in rhs.eitherT.map(const(a)) }.rawValue
                #expect(lhs.eitherT.seqLeft(rhs.eitherT).rawValue == seqLeftViaBind)
            }
        }
    }

    @Test func eitherTResultFailureBeforeLeftShortCircuits() {
        let fns: Either<String, Result<@Sendable (Int) -> Int, StackError>> = .right(.failure(.fromFunction))
        let values: Either<String, Result<Int, StackError>> = .left("l")
        #expect(EitherTResult.apply(fns.eitherT, values.eitherT).rawValue == .right(.failure(.fromFunction)))
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
                let viaBind = fns.optionalT.flatMap { fn in values.optionalT.map(fn) }.rawValue
                #expect(OptionalTEither.apply(fns.optionalT, values.optionalT).rawValue == viaBind)
            }
        }
    }

    @Test func optionalTEitherLiftA2IsBind() {
        let lifted = OptionalTEither<String, Int>.liftA2 { (a: Int, b: Int) in a * 100 + b }
        for lhs in Self.optionalEitherXs {
            for rhs in Self.optionalEitherYs {
                let viaBind = lhs.optionalT.flatMap { a in rhs.optionalT.map { b in a * 100 + b } }.rawValue
                #expect(lifted(lhs.optionalT, rhs.optionalT).rawValue == viaBind)
            }
        }
    }

    @Test func optionalTEitherSeqRightSeqLeftAreBind() {
        for lhs in Self.optionalEitherXs {
            for rhs in Self.optionalEitherYs {
                #expect(lhs.optionalT.seqRight(rhs.optionalT).rawValue == lhs.optionalT.flatMap(const(rhs.optionalT)).rawValue)
                let seqLeftViaBind = lhs.optionalT.flatMap { a in rhs.optionalT.map(const(a)) }.rawValue
                #expect(lhs.optionalT.seqLeft(rhs.optionalT).rawValue == seqLeftViaBind)
            }
        }
    }

    @Test func optionalTEitherLeftBeforeNoneShortCircuits() {
        let fns: Either<String, @Sendable (Int) -> Int>? = .some(.left("l"))
        let values: Either<String, Int>? = nil
        #expect(OptionalTEither.apply(fns.optionalT, values.optionalT).rawValue == .some(.left("l")))
    }
}
