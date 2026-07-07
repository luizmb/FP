// SPDX-License-Identifier: Apache-2.0
import CoreFP
import DataStructure
import Testing

/// Core (named-function) coverage for the "Validation-outer" transformer combos:
/// `Validation<E, Inner>` where `Inner` is `Either`, `Reader`, `Result`, `Stateful`, or `Writer`.
///
/// `ValidationTArray` and `ValidationTOptional` are already covered in `ValidationTests.swift`.
/// `ValidationTNonEmpty` (Functor + Applicative) is covered in `ValidationTNonEmptyApplicativeTests.swift`
/// and `ValidationTNonEmpty+Tests.swift`.
///
/// Validation is an accumulating Applicative, not a Monad — there is no `flatMapT` for any of
/// these combos and none is referenced here.
@Suite struct ValidationOuterTransformerTests {
    // MARK: - Transformer: ValidationTEither

    @Test func validationTEitherMapT() {
        let v: Validation<[String], Either<String, Int>> = .success(.right(5))
        let result = mapTValidationEither { $0 * 2 }(v)
        #expect(result == .success(.right(10)))
    }

    @Test func validationTEitherApplyAccumulatesErrors() {
        let vf: Validation<[String], Either<String, @Sendable (Int) -> Int>> = .failure(["e1"])
        let va: Validation<[String], Either<String, Int>> = .failure(["e2"])
        let result = applyValidationEither(vf, va)
        #expect(result.is(.failure), "Expected failure")
        if case let .failure(e) = result { #expect(e == ["e1", "e2"]) }
    }

    @Test func validationTEitherApplySuccessSuccess() {
        let vf: Validation<[String], Either<String, @Sendable (Int) -> Int>> = .success(.right { $0 + 1 })
        let va: Validation<[String], Either<String, Int>> = .success(.right(5))
        #expect(applyValidationEither(vf, va) == .success(.right(6)))
    }

    // MARK: - Transformer: ValidationTReader

    @Test func validationTReaderMapT() {
        let v: Validation<[String], Reader<String, Int>> = .success(Reader { env in env.count })
        let result = mapTValidationReader { $0 * 2 }(v)
        if case let .success(reader) = result {
            #expect(reader("hello") == 10)
        } else {
            Issue.record("Expected .success")
        }
    }

    @Test func validationTReaderApplyAccumulatesErrors() {
        let vf: Validation<[String], Reader<String, @Sendable (Int) -> Int>> = .failure(["e1"])
        let va: Validation<[String], Reader<String, Int>> = .failure(["e2"])
        let result = applyValidationReader(vf, va)
        #expect(result.is(.failure), "Expected failure")
        if case let .failure(e) = result { #expect(e == ["e1", "e2"]) }
    }

    @Test func validationTReaderApplySuccessSuccess() {
        let increment: @Sendable (Int) -> Int = { $0 + 1 }
        let vf: Validation<[String], Reader<String, @Sendable (Int) -> Int>> = .success(Reader(const(increment)))
        let va: Validation<[String], Reader<String, Int>> = .success(Reader { env in env.count })
        let result = applyValidationReader(vf, va)
        if case let .success(reader) = result {
            #expect(reader("hello") == 6)
        } else {
            Issue.record("Expected .success")
        }
    }

    // MARK: - Transformer: ValidationTResult

    @Test func validationTResultMapT() {
        let v: Validation<[String], Result<Int, TestError>> = .success(.success(5))
        let result = mapTValidationResult { $0 * 2 }(v)
        if case let .success(inner) = result, case let .success(value) = inner {
            #expect(value == 10)
        } else {
            Issue.record("Expected .success(.success)")
        }
    }

    @Test func validationTResultApplyAccumulatesErrors() {
        let vf: Validation<[String], Result<@Sendable (Int) -> Int, TestError>> = .failure(["e1"])
        let va: Validation<[String], Result<Int, TestError>> = .failure(["e2"])
        let result = applyValidationResult(vf, va)
        #expect(result.is(.failure), "Expected failure")
        if case let .failure(e) = result { #expect(e == ["e1", "e2"]) }
    }

    @Test func validationTResultApplySuccessSuccess() {
        let vf: Validation<[String], Result<@Sendable (Int) -> Int, TestError>> = .success(.success { $0 + 1 })
        let va: Validation<[String], Result<Int, TestError>> = .success(.success(5))
        let result = applyValidationResult(vf, va)
        if case let .success(inner) = result, case let .success(value) = inner {
            #expect(value == 6)
        } else {
            Issue.record("Expected .success(.success)")
        }
    }

    // MARK: - Transformer: ValidationTStateful

    @Test func validationTStatefulMapT() {
        let v: Validation<[String], Stateful<Int, Int>> = .success(Stateful { s in
            s += 1
            return s
        })
        let result = mapTValidationStateful { $0 * 2 }(v)
        if case let .success(stateful) = result {
            var state = 0
            #expect(stateful.run(&state) == 2)
            #expect(state == 1)
        } else {
            Issue.record("Expected .success")
        }
    }

    @Test func validationTStatefulApplyAccumulatesErrors() {
        let vf: Validation<[String], Stateful<Int, @Sendable (Int) -> Int>> = .failure(["e1"])
        let va: Validation<[String], Stateful<Int, Int>> = .failure(["e2"])
        let result = applyValidationStateful(vf, va)
        #expect(result.is(.failure), "Expected failure")
        if case let .failure(e) = result { #expect(e == ["e1", "e2"]) }
    }

    @Test func validationTStatefulApplySuccessSuccess() {
        let vf: Validation<[String], Stateful<Int, @Sendable (Int) -> Int>> =
            .success(Stateful<Int, @Sendable (Int) -> Int>.pure { $0 + 1 })
        let va: Validation<[String], Stateful<Int, Int>> = .success(Stateful { s in
            s += 1
            return s
        })
        let result = applyValidationStateful(vf, va)
        if case let .success(stateful) = result {
            var state = 0
            #expect(stateful.run(&state) == 2)
            #expect(state == 1)
        } else {
            Issue.record("Expected .success")
        }
    }

    // MARK: - Transformer: ValidationTWriter

    @Test func validationTWriterMapT() {
        let v: Validation<[String], Writer<[String], Int>> = .success(Writer(5, ["log"]))
        let result = mapTValidationWriter { $0 * 2 }(v)
        #expect(result == .success(Writer(10, ["log"])))
    }

    @Test func validationTWriterApplyAccumulatesErrors() {
        let vf: Validation<[String], Writer<[String], @Sendable (Int) -> Int>> = .failure(["e1"])
        let va: Validation<[String], Writer<[String], Int>> = .failure(["e2"])
        #expect((applyValidationWriter(vf, va)) == .failure(["e1", "e2"]))
    }

    @Test func validationTWriterApplySuccessSuccess() {
        let increment: @Sendable (Int) -> Int = { $0 + 1 }
        let vf: Validation<[String], Writer<[String], @Sendable (Int) -> Int>> = .success(Writer(increment, ["f"]))
        let va: Validation<[String], Writer<[String], Int>> = .success(Writer(5, ["a"]))
        #expect(applyValidationWriter(vf, va) == .success(Writer(6, ["f", "a"])))
    }

    // MARK: - Helpers

    enum TestError: Error, Equatable { case boom }
}
