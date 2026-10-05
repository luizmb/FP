// SPDX-License-Identifier: Apache-2.0
import CoreFP
import DataStructure
import Testing

/// Core (named-function) coverage for the "Validation-outer" transformer stacks:
/// `ValidationTArray`, `ValidationTEither`, `ValidationTNonEmpty`, `ValidationTOptional`,
/// `ValidationTReader`, `ValidationTResult`, `ValidationTStateful` and `ValidationTWriter`.
///
/// Validation is an accumulating Applicative, not a Monad, so every stack is applicative-only
/// (`TransformerStack`): the laws checked here are functor identity/composition and applicative
/// identity/homomorphism, with errors accumulating across `apply`.
@Suite struct ValidationOuterTransformerTests {
    // MARK: - ValidationTArray

    @Test func validationTArrayMap() {
        let stack = ValidationTArray<[String], Int>(.success([1, 2, 3]))
        #expect(stack.map { $0 * 2 }.rawValue == .success([2, 4, 6]))
    }

    @Test func validationTArrayApplyAccumulatesErrors() {
        let vf = ValidationTArray<[String], @Sendable (Int) -> Int>(.failure(["e1"]))
        let va = ValidationTArray<[String], Int>(.failure(["e2"]))
        #expect(ValidationTArray.apply(vf, va).rawValue == .failure(["e1", "e2"]))
    }

    @Test func validationTArrayFunctorLaws() {
        let stacks: [ValidationTArray<[String], Int>] = [.init(.success([1, 2])), .init(.failure(["e"]))]
        for stack in stacks {
            #expect(stack.map(id).rawValue == stack.rawValue)
            #expect(stack.map(double).map(increment).rawValue == stack.map { increment(double($0)) }.rawValue)
        }
    }

    @Test func validationTArrayApplicativeLaws() {
        let stacks: [ValidationTArray<[String], Int>] = [.init(.success([1, 2])), .init(.failure(["e"]))]
        for stack in stacks {
            #expect(ValidationTArray.apply(.pure(identityFn), stack).rawValue == stack.rawValue)
        }
        let homomorphism = ValidationTArray<[String], Int>.apply(.pure(increment), .pure(4))
        #expect(homomorphism.rawValue == ValidationTArray<[String], Int>.pure(increment(4)).rawValue)
    }

    @Test func validationTArrayMapValidationT() {
        let stack = ValidationTArray<[String], Int>(.failure(["abc"]))
        #expect(stack.mapValidationT { $0.mapFailure { $0.map(\.count) } }.rawValue == .failure([3]))
    }

    @Test func validationTArrayLifting() {
        let nested: Validation<[String], [Int]> = .success([1, 2])
        #expect(nested.validationT.rawValue == nested)
    }

    // MARK: - ValidationTEither

    @Test func validationTEitherMap() {
        let stack = ValidationTEither<[String], String, Int>(.success(.right(5)))
        #expect(stack.map { $0 * 2 }.rawValue == .success(.right(10)))
    }

    @Test func validationTEitherApplyAccumulatesErrors() {
        let vf = ValidationTEither<[String], String, @Sendable (Int) -> Int>(.failure(["e1"]))
        let va = ValidationTEither<[String], String, Int>(.failure(["e2"]))
        let result = ValidationTEither.apply(vf, va).rawValue
        #expect(result.is(.failure), "Expected failure")
        if case let .failure(e) = result { #expect(e == ["e1", "e2"]) }
    }

    @Test func validationTEitherApplySuccessSuccess() {
        let vf = ValidationTEither<[String], String, @Sendable (Int) -> Int>(.success(.right { $0 + 1 }))
        let va = ValidationTEither<[String], String, Int>(.success(.right(5)))
        #expect(ValidationTEither.apply(vf, va).rawValue == .success(.right(6)))
    }

    @Test func validationTEitherFunctorLaws() {
        let stacks: [ValidationTEither<[String], String, Int>] = [
            .init(.success(.right(1))),
            .init(.success(.left("l"))),
            .init(.failure(["e"]))
        ]
        for stack in stacks {
            #expect(stack.map(id).rawValue == stack.rawValue)
            #expect(stack.map(double).map(increment).rawValue == stack.map { increment(double($0)) }.rawValue)
        }
    }

    @Test func validationTEitherApplicativeLaws() {
        let stacks: [ValidationTEither<[String], String, Int>] = [
            .init(.success(.right(1))),
            .init(.success(.left("l"))),
            .init(.failure(["e"]))
        ]
        for stack in stacks {
            #expect(ValidationTEither.apply(.pure(identityFn), stack).rawValue == stack.rawValue)
        }
        let homomorphism = ValidationTEither<[String], String, Int>.apply(.pure(increment), .pure(4))
        #expect(homomorphism.rawValue == ValidationTEither<[String], String, Int>.pure(increment(4)).rawValue)
    }

    @Test func validationTEitherMapExceptT() {
        let stack = ValidationTEither<[String], String, Int>(.failure(["abc"]))
        #expect(stack.mapExceptT { $0.mapFailure { $0.map(\.count) } }.rawValue == .failure([3]))
    }

    @Test func validationTEitherLifting() {
        let nested: Validation<[String], Either<String, Int>> = .success(.right(1))
        #expect(nested.validationT.rawValue == nested)
    }

    // MARK: - ValidationTNonEmpty

    @Test func validationTNonEmptyFmapSuccess() {
        let stack = ValidationTNonEmpty<String, Int>(.success(NonEmpty(head: 1, tail: [2, 3])))
        let result = ValidationTNonEmpty<String, Int>.fmap { $0 * 10 }(stack)
        #expect(result.rawValue == .success(NonEmpty(head: 10, tail: [20, 30])))
    }

    @Test func validationTNonEmptyFmapFailurePropagates() {
        let stack = ValidationTNonEmpty<String, Int>(.failure("err"))
        let result = ValidationTNonEmpty<String, Int>.fmap { $0 * 10 }(stack)
        #expect(result.rawValue == .failure("err"))
    }

    @Test func validationTNonEmptyApplyAccumulatesErrors() {
        let vf = ValidationTNonEmpty<[String], @Sendable (Int) -> Int>(.failure(["e1"]))
        let va = ValidationTNonEmpty<[String], Int>(.failure(["e2"]))
        let result = ValidationTNonEmpty.apply(vf, va).rawValue
        #expect(result.is(.failure), "Expected failure")
        if case let .failure(e) = result { #expect(e == ["e1", "e2"]) }
    }

    @Test func validationTNonEmptyApplySuccessSuccess() {
        let vf = ValidationTNonEmpty<[String], @Sendable (Int) -> Int>(.success(NonEmpty(head: increment)))
        let va = ValidationTNonEmpty<[String], Int>(.success(NonEmpty(head: 5, tail: [10])))
        #expect(ValidationTNonEmpty.apply(vf, va).rawValue == .success(NonEmpty(head: 6, tail: [11])))
    }

    @Test func validationTNonEmptyLiftA2AccumulatesErrors() {
        let va = ValidationTNonEmpty<[String], Int>(.failure(["e1"]))
        let vb = ValidationTNonEmpty<[String], Int>(.failure(["e2"]))
        let result = ValidationTNonEmpty<[String], Int>.liftA2 { (a: Int, b: Int) in a + b }(va, vb).rawValue
        #expect(result.is(.failure), "Expected failure")
        if case let .failure(e) = result { #expect(e == ["e1", "e2"]) }
    }

    @Test func validationTNonEmptyLiftA2SuccessSuccess() {
        let va = ValidationTNonEmpty<[String], Int>(.success(NonEmpty(head: 1)))
        let vb = ValidationTNonEmpty<[String], Int>(.success(NonEmpty(head: 10)))
        let result = ValidationTNonEmpty<[String], Int>.liftA2 { (a: Int, b: Int) in a + b }(va, vb)
        #expect(result.rawValue == .success(NonEmpty(head: 11)))
    }

    @Test func validationTNonEmptySeqRightAccumulatesErrors() {
        let lhs = ValidationTNonEmpty<[String], Int>(.failure(["e1"]))
        let rhs = ValidationTNonEmpty<[String], Int>(.failure(["e2"]))
        let result = lhs.seqRight(rhs).rawValue
        #expect(result.is(.failure), "Expected failure")
        if case let .failure(e) = result { #expect(e == ["e1", "e2"]) }
    }

    @Test func validationTNonEmptySeqRightSuccessSuccess() {
        let lhs = ValidationTNonEmpty<[String], Int>(.success(NonEmpty(head: 1)))
        let rhs = ValidationTNonEmpty<[String], Int>(.success(NonEmpty(head: 10)))
        #expect(lhs.seqRight(rhs).rawValue == .success(NonEmpty(head: 10)))
    }

    @Test func validationTNonEmptySeqLeftSuccessSuccess() {
        let lhs = ValidationTNonEmpty<[String], Int>(.success(NonEmpty(head: 1)))
        let rhs = ValidationTNonEmpty<[String], Int>(.success(NonEmpty(head: 10)))
        #expect(lhs.seqLeft(rhs).rawValue == .success(NonEmpty(head: 1)))
    }

    @Test func validationTNonEmptyFunctorLaws() {
        let stacks: [ValidationTNonEmpty<[String], Int>] = [
            .init(.success(NonEmpty(head: 1, tail: [2]))),
            .init(.failure(["e"]))
        ]
        for stack in stacks {
            #expect(stack.map(id).rawValue == stack.rawValue)
            #expect(stack.map(double).map(increment).rawValue == stack.map { increment(double($0)) }.rawValue)
        }
    }

    @Test func validationTNonEmptyApplicativeLaws() {
        let stacks: [ValidationTNonEmpty<[String], Int>] = [
            .init(.success(NonEmpty(head: 1, tail: [2]))),
            .init(.failure(["e"]))
        ]
        for stack in stacks {
            #expect(ValidationTNonEmpty.apply(.pure(identityFn), stack).rawValue == stack.rawValue)
        }
        let homomorphism = ValidationTNonEmpty<[String], Int>.apply(.pure(increment), .pure(4))
        #expect(homomorphism.rawValue == ValidationTNonEmpty<[String], Int>.pure(increment(4)).rawValue)
    }

    @Test func validationTNonEmptyMapValidationT() {
        let stack = ValidationTNonEmpty<[String], Int>(.failure(["abc"]))
        #expect(stack.mapValidationT { $0.mapFailure { $0.map(\.count) } }.rawValue == .failure([3]))
    }

    @Test func validationTNonEmptyLifting() {
        let nested: Validation<[String], NonEmpty<Int>> = .success(NonEmpty(head: 1, tail: [2]))
        #expect(nested.validationT.rawValue == nested)
    }

    // MARK: - ValidationTOptional

    @Test func validationTOptionalMap() {
        let stack = ValidationTOptional<[String], Int>(.success(.some(5)))
        #expect(stack.map { $0 * 2 }.rawValue == .success(.some(10)))
    }

    @Test func validationTOptionalApplyBothFailures() {
        let vf = ValidationTOptional<[String], @Sendable (Int) -> Int>(.failure(["e1"]))
        let va = ValidationTOptional<[String], Int>(.failure(["e2"]))
        #expect(ValidationTOptional.apply(vf, va).rawValue == .failure(["e1", "e2"]))
    }

    @Test func validationTOptionalFunctorLaws() {
        let stacks: [ValidationTOptional<[String], Int>] = [.init(.success(1)), .init(.success(nil)), .init(.failure(["e"]))]
        for stack in stacks {
            #expect(stack.map(id).rawValue == stack.rawValue)
            #expect(stack.map(double).map(increment).rawValue == stack.map { increment(double($0)) }.rawValue)
        }
    }

    @Test func validationTOptionalApplicativeLaws() {
        let stacks: [ValidationTOptional<[String], Int>] = [.init(.success(1)), .init(.success(nil)), .init(.failure(["e"]))]
        for stack in stacks {
            #expect(ValidationTOptional.apply(.pure(identityFn), stack).rawValue == stack.rawValue)
        }
        let homomorphism = ValidationTOptional<[String], Int>.apply(.pure(increment), .pure(4))
        #expect(homomorphism.rawValue == ValidationTOptional<[String], Int>.pure(increment(4)).rawValue)
    }

    @Test func validationTOptionalMapMaybeT() {
        let stack = ValidationTOptional<[String], Int>(.failure(["abc"]))
        #expect(stack.mapMaybeT { $0.mapFailure { $0.map(\.count) } }.rawValue == .failure([3]))
    }

    @Test func validationTOptionalLifting() {
        let nested: Validation<[String], Int?> = .success(nil)
        #expect(nested.validationT.rawValue == nested)
    }

    // MARK: - ValidationTReader

    @Test func validationTReaderMap() {
        let stack = ValidationTReader<[String], String, Int>(.success(Reader { env in env.count }))
        #expect(runReader(stack.map { $0 * 2 }) == .success(10))
    }

    @Test func validationTReaderApplyAccumulatesErrors() {
        let vf = ValidationTReader<[String], String, @Sendable (Int) -> Int>(.failure(["e1"]))
        let va = ValidationTReader<[String], String, Int>(.failure(["e2"]))
        #expect(runReader(ValidationTReader.apply(vf, va)) == .failure(["e1", "e2"]))
    }

    @Test func validationTReaderApplySuccessSuccess() {
        let vf = ValidationTReader<[String], String, @Sendable (Int) -> Int>(.success(Reader(const(increment))))
        let va = ValidationTReader<[String], String, Int>(.success(Reader { env in env.count }))
        #expect(runReader(ValidationTReader.apply(vf, va)) == .success(6))
    }

    @Test func validationTReaderFunctorLaws() {
        let stacks: [ValidationTReader<[String], String, Int>] = [
            .init(.success(Reader { env in env.count })),
            .init(.failure(["e"]))
        ]
        for stack in stacks {
            #expect(runReader(stack.map(id)) == runReader(stack))
            #expect(runReader(stack.map(double).map(increment)) == runReader(stack.map { increment(double($0)) }))
        }
    }

    @Test func validationTReaderApplicativeLaws() {
        let stacks: [ValidationTReader<[String], String, Int>] = [
            .init(.success(Reader { env in env.count })),
            .init(.failure(["e"]))
        ]
        for stack in stacks {
            #expect(runReader(ValidationTReader.apply(.pure(identityFn), stack)) == runReader(stack))
        }
        let homomorphism = ValidationTReader<[String], String, Int>.apply(.pure(increment), .pure(4))
        #expect(runReader(homomorphism) == runReader(ValidationTReader<[String], String, Int>.pure(increment(4))))
    }

    @Test func validationTReaderMapValidationT() {
        let stack = ValidationTReader<[String], String, Int>(.success(Reader { env in env.count }))
        let localised = stack.mapValidationT { $0.map { $0.local { $0 + "!" } } }
        #expect(runReader(localised) == .success(6))
    }

    @Test func validationTReaderLifting() {
        let nested: Validation<[String], Reader<String, Int>> = .success(Reader { env in env.count })
        #expect(runReader(nested.validationT) == .success(5))
    }

    // MARK: - ValidationTResult

    @Test func validationTResultMap() {
        let stack = ValidationTResult<[String], TestError, Int>(.success(.success(5)))
        #expect(stack.map { $0 * 2 }.rawValue == .success(.success(10)))
    }

    @Test func validationTResultApplyAccumulatesErrors() {
        let vf = ValidationTResult<[String], TestError, @Sendable (Int) -> Int>(.failure(["e1"]))
        let va = ValidationTResult<[String], TestError, Int>(.failure(["e2"]))
        let result = ValidationTResult.apply(vf, va).rawValue
        #expect(result.is(.failure), "Expected failure")
        if case let .failure(e) = result { #expect(e == ["e1", "e2"]) }
    }

    @Test func validationTResultApplySuccessSuccess() {
        let vf = ValidationTResult<[String], TestError, @Sendable (Int) -> Int>(.success(.success { $0 + 1 }))
        let va = ValidationTResult<[String], TestError, Int>(.success(.success(5)))
        #expect(ValidationTResult.apply(vf, va).rawValue == .success(.success(6)))
    }

    @Test func validationTResultFunctorLaws() {
        let stacks: [ValidationTResult<[String], TestError, Int>] = [
            .init(.success(.success(1))),
            .init(.success(.failure(.boom))),
            .init(.failure(["e"]))
        ]
        for stack in stacks {
            #expect(stack.map(id).rawValue == stack.rawValue)
            #expect(stack.map(double).map(increment).rawValue == stack.map { increment(double($0)) }.rawValue)
        }
    }

    @Test func validationTResultApplicativeLaws() {
        let stacks: [ValidationTResult<[String], TestError, Int>] = [
            .init(.success(.success(1))),
            .init(.success(.failure(.boom))),
            .init(.failure(["e"]))
        ]
        for stack in stacks {
            #expect(ValidationTResult.apply(.pure(identityFn), stack).rawValue == stack.rawValue)
        }
        let homomorphism = ValidationTResult<[String], TestError, Int>.apply(.pure(increment), .pure(4))
        #expect(homomorphism.rawValue == ValidationTResult<[String], TestError, Int>.pure(increment(4)).rawValue)
    }

    @Test func validationTResultMapExceptT() {
        let stack = ValidationTResult<[String], TestError, Int>(.failure(["abc"]))
        #expect(stack.mapExceptT { $0.mapFailure { $0.map(\.count) } }.rawValue == .failure([3]))
    }

    @Test func validationTResultLifting() {
        let nested: Validation<[String], Result<Int, TestError>> = .success(.failure(.boom))
        #expect(nested.validationT.rawValue == nested)
    }

    // MARK: - ValidationTStateful

    @Test func validationTStatefulMap() {
        let stack = ValidationTStateful<[String], Int, Int>(.success(tick))
        #expect(runStateful(stack.map { $0 * 2 }) == .success([2, 1]))
    }

    @Test func validationTStatefulApplyAccumulatesErrors() {
        let vf = ValidationTStateful<[String], Int, @Sendable (Int) -> Int>(.failure(["e1"]))
        let va = ValidationTStateful<[String], Int, Int>(.failure(["e2"]))
        #expect(runStateful(ValidationTStateful.apply(vf, va)) == .failure(["e1", "e2"]))
    }

    @Test func validationTStatefulApplySuccessSuccess() {
        let vf = ValidationTStateful<[String], Int, @Sendable (Int) -> Int>(.success(.pure(increment)))
        let va = ValidationTStateful<[String], Int, Int>(.success(tick))
        #expect(runStateful(ValidationTStateful.apply(vf, va)) == .success([2, 1]))
    }

    @Test func validationTStatefulFunctorLaws() {
        let stacks: [ValidationTStateful<[String], Int, Int>] = [.init(.success(tick)), .init(.failure(["e"]))]
        for stack in stacks {
            #expect(runStateful(stack.map(id)) == runStateful(stack))
            #expect(runStateful(stack.map(double).map(increment)) == runStateful(stack.map { increment(double($0)) }))
        }
    }

    @Test func validationTStatefulApplicativeLaws() {
        let stacks: [ValidationTStateful<[String], Int, Int>] = [.init(.success(tick)), .init(.failure(["e"]))]
        for stack in stacks {
            #expect(runStateful(ValidationTStateful.apply(.pure(identityFn), stack)) == runStateful(stack))
        }
        let homomorphism = ValidationTStateful<[String], Int, Int>.apply(.pure(increment), .pure(4))
        #expect(runStateful(homomorphism) == runStateful(ValidationTStateful<[String], Int, Int>.pure(increment(4))))
    }

    @Test func validationTStatefulMapValidationT() {
        let stack = ValidationTStateful<[String], Int, Int>(.failure(["abc"]))
        let mapped = stack.mapValidationT { $0.mapFailure { $0.map(\.count) } }
        #expect(mapped.rawValue.map(stateAndValue) == .failure([3]))
    }

    @Test func validationTStatefulLifting() {
        let nested: Validation<[String], Stateful<Int, Int>> = .success(tick)
        #expect(runStateful(nested.validationT) == .success([1, 1]))
    }

    // MARK: - ValidationTWriter

    @Test func validationTWriterMap() {
        let stack = ValidationTWriter<[String], [String], Int>(.success(Writer(5, ["log"])))
        #expect(stack.map { $0 * 2 }.rawValue == .success(Writer(10, ["log"])))
    }

    @Test func validationTWriterApplyAccumulatesErrors() {
        let vf = ValidationTWriter<[String], [String], @Sendable (Int) -> Int>(.failure(["e1"]))
        let va = ValidationTWriter<[String], [String], Int>(.failure(["e2"]))
        #expect(ValidationTWriter.apply(vf, va).rawValue == .failure(["e1", "e2"]))
    }

    @Test func validationTWriterApplySuccessSuccess() {
        let vf = ValidationTWriter<[String], [String], @Sendable (Int) -> Int>(.success(Writer(increment, ["f"])))
        let va = ValidationTWriter<[String], [String], Int>(.success(Writer(5, ["a"])))
        #expect(ValidationTWriter.apply(vf, va).rawValue == .success(Writer(6, ["f", "a"])))
    }

    @Test func validationTWriterFunctorLaws() {
        let stacks: [ValidationTWriter<[String], [String], Int>] = [.init(.success(Writer(1, ["log"]))), .init(.failure(["e"]))]
        for stack in stacks {
            #expect(stack.map(id).rawValue == stack.rawValue)
            #expect(stack.map(double).map(increment).rawValue == stack.map { increment(double($0)) }.rawValue)
        }
    }

    @Test func validationTWriterApplicativeLaws() {
        let stacks: [ValidationTWriter<[String], [String], Int>] = [.init(.success(Writer(1, ["log"]))), .init(.failure(["e"]))]
        for stack in stacks {
            #expect(ValidationTWriter.apply(.pure(identityFn), stack).rawValue == stack.rawValue)
        }
        let homomorphism = ValidationTWriter<[String], [String], Int>.apply(.pure(increment), .pure(4))
        #expect(homomorphism.rawValue == ValidationTWriter<[String], [String], Int>.pure(increment(4)).rawValue)
    }

    @Test func validationTWriterMapWriterT() {
        let stack = ValidationTWriter<[String], [String], Int>(.success(Writer(1, ["secret"])))
        let censored = stack.mapWriterT { $0.map { $0.censor(const(["censored"])) } }
        #expect(censored.rawValue == .success(Writer(1, ["censored"])))
    }

    @Test func validationTWriterLifting() {
        let nested: Validation<[String], Writer<[String], Int>> = .success(Writer(1, ["log"]))
        #expect(nested.validationT.rawValue == nested)
    }

    // MARK: - Helpers

    enum TestError: Error, Equatable { case boom }

    let double: @Sendable (Int) -> Int = { $0 * 2 }
    let increment: @Sendable (Int) -> Int = { $0 + 1 }
    let identityFn: @Sendable (Int) -> Int = id

    /// Increments the state and returns the new state.
    let tick = Stateful<Int, Int> { s in
        s += 1
        return s
    }

    /// Runs the inner Reader with the environment `"hello"`.
    func runReader(_ stack: ValidationTReader<[String], String, Int>) -> Validation<[String], Int> {
        stack.rawValue.map { $0("hello") }
    }

    /// Runs the inner Stateful from state `0`, observing `[value, finalState]`.
    func runStateful(_ stack: ValidationTStateful<[String], Int, Int>) -> Validation<[String], [Int]> {
        stack.rawValue.map(stateAndValue)
    }
}

/// Runs a Stateful from state `0`, observing `[value, finalState]`.
private let stateAndValue: @Sendable (Stateful<Int, Int>) -> [Int] = { stateful in
    [stateful.runStateful(0).0, stateful.runStateful(0).1]
}
