// SPDX-License-Identifier: Apache-2.0
import CoreFP
import CoreFPOperators
import DataStructure
import DataStructureOperators
import Testing

/// Operator-syntax coverage for the "Validation-outer" transformer combos:
/// `Validation<E, Inner>` where `Inner` is `Array`, `Either`, `Optional`, `Reader`, `Result`,
/// `Stateful`, or `Writer`.
///
/// Validation is an accumulating Applicative, not a Monad — there is no `flatMapT`/`>>-` for
/// any of these combos and none is referenced here.
@Suite struct ValidationOuterTransformerOperatorsTests {
    // MARK: - ValidationTArray

    @Test func validationTArrayFunctorOperator() {
        let v: Validation<[String], [Int]> = .success([1, 2, 3])
        let result = { $0 * 2 } <£^> v
        #expect(result == .success([2, 4, 6]))
    }

    @Test func validationTArrayApplyOperatorAccumulatesErrors() {
        let vf: Validation<[String], [@Sendable (Int) -> Int]> = .failure(["e1"])
        let va: Validation<[String], [Int]> = .failure(["e2"])
        #expect((vf <*> va) == .failure(["e1", "e2"]))
    }

    @Test func validationTArraySeqRightOperatorAccumulatesErrors() {
        let lhs: Validation<[String], [Int]> = .failure(["e1"])
        let rhs: Validation<[String], [String]> = .failure(["e2"])
        #expect((lhs *> rhs) == .failure(["e1", "e2"]))
    }

    // MARK: - ValidationTEither

    @Test func validationTEitherFunctorOperator() {
        let v: Validation<[String], Either<String, Int>> = .success(.right(5))
        let result = { $0 * 2 } <£^> v
        #expect(result == .success(.right(10)))
    }

    @Test func validationTEitherApplyOperatorAccumulatesErrors() {
        let vf: Validation<[String], Either<String, @Sendable (Int) -> Int>> = .failure(["e1"])
        let va: Validation<[String], Either<String, Int>> = .failure(["e2"])
        #expect((vf <*> va) == .failure(["e1", "e2"]))
    }

    @Test func validationTEitherSeqLeftOperatorAccumulatesErrors() {
        let lhs: Validation<[String], Either<String, Int>> = .failure(["e1"])
        let rhs: Validation<[String], Either<String, String>> = .failure(["e2"])
        #expect((lhs <* rhs) == .failure(["e1", "e2"]))
    }

    // MARK: - ValidationTOptional

    @Test func validationTOptionalFunctorOperator() {
        let v: Validation<[String], Int?> = .success(.some(5))
        let result = { $0 * 2 } <£^> v
        #expect(result == .success(.some(10)))
    }

    @Test func validationTOptionalApplyOperatorAccumulatesErrors() {
        let vf: Validation<[String], (@Sendable (Int) -> Int)?> = .failure(["e1"])
        let va: Validation<[String], Int?> = .failure(["e2"])
        #expect((vf <*> va) == .failure(["e1", "e2"]))
    }

    @Test func validationTOptionalSeqRightOperatorAccumulatesErrors() {
        let lhs: Validation<[String], Int?> = .failure(["e1"])
        let rhs: Validation<[String], String?> = .failure(["e2"])
        #expect((lhs *> rhs) == .failure(["e1", "e2"]))
    }

    // MARK: - ValidationTReader

    @Test func validationTReaderFunctorOperator() {
        let v: Validation<[String], Reader<String, Int>> = .success(Reader { env in env.count })
        let result = { $0 * 2 } <£^> v
        if case let .success(reader) = result {
            #expect(reader("hello") == 10)
        } else {
            Issue.record("Expected .success")
        }
    }

    @Test func validationTReaderApplyOperatorAccumulatesErrors() {
        let vf: Validation<[String], Reader<String, @Sendable (Int) -> Int>> = .failure(["e1"])
        let va: Validation<[String], Reader<String, Int>> = .failure(["e2"])
        let result = vf <*> va
        #expect(result.is(.failure), "Expected failure")
        if case let .failure(e) = result { #expect(e == ["e1", "e2"]) }
    }

    @Test func validationTReaderSeqLeftOperatorAccumulatesErrors() {
        let lhs: Validation<[String], Reader<String, Int>> = .failure(["e1"])
        let rhs: Validation<[String], Reader<String, String>> = .failure(["e2"])
        let result = lhs <* rhs
        #expect(result.is(.failure), "Expected failure")
        if case let .failure(e) = result { #expect(e == ["e1", "e2"]) }
    }

    // MARK: - ValidationTResult

    @Test func validationTResultFunctorOperator() {
        let v: Validation<[String], Result<Int, TestError>> = .success(.success(5))
        let result = { $0 * 2 } <£^> v
        if case let .success(inner) = result, case let .success(value) = inner {
            #expect(value == 10)
        } else {
            Issue.record("Expected .success(.success)")
        }
    }

    @Test func validationTResultApplyOperatorAccumulatesErrors() {
        let vf: Validation<[String], Result<@Sendable (Int) -> Int, TestError>> = .failure(["e1"])
        let va: Validation<[String], Result<Int, TestError>> = .failure(["e2"])
        let result = vf <*> va
        #expect(result.is(.failure), "Expected failure")
        if case let .failure(e) = result { #expect(e == ["e1", "e2"]) }
    }

    @Test func validationTResultSeqRightOperatorAccumulatesErrors() {
        let lhs: Validation<[String], Result<Int, TestError>> = .failure(["e1"])
        let rhs: Validation<[String], Result<String, TestError>> = .failure(["e2"])
        let result = lhs *> rhs
        #expect(result.is(.failure), "Expected failure")
        if case let .failure(e) = result { #expect(e == ["e1", "e2"]) }
    }

    // MARK: - ValidationTStateful

    @Test func validationTStatefulFunctorOperator() {
        let v: Validation<[String], Stateful<Int, Int>> = .success(Stateful { s in
            s += 1
            return s
        })
        let result = { $0 * 2 } <£^> v
        if case let .success(stateful) = result {
            var state = 0
            #expect(stateful.run(&state) == 2)
            #expect(state == 1)
        } else {
            Issue.record("Expected .success")
        }
    }

    @Test func validationTStatefulApplyOperatorAccumulatesErrors() {
        let vf: Validation<[String], Stateful<Int, @Sendable (Int) -> Int>> = .failure(["e1"])
        let va: Validation<[String], Stateful<Int, Int>> = .failure(["e2"])
        let result = vf <*> va
        #expect(result.is(.failure), "Expected failure")
        if case let .failure(e) = result { #expect(e == ["e1", "e2"]) }
    }

    @Test func validationTStatefulSeqLeftOperatorAccumulatesErrors() {
        let lhs: Validation<[String], Stateful<Int, Int>> = .failure(["e1"])
        let rhs: Validation<[String], Stateful<Int, String>> = .failure(["e2"])
        let result = lhs <* rhs
        #expect(result.is(.failure), "Expected failure")
        if case let .failure(e) = result { #expect(e == ["e1", "e2"]) }
    }

    // MARK: - ValidationTWriter

    @Test func validationTWriterFunctorOperator() {
        let v: Validation<[String], Writer<[String], Int>> = .success(Writer(5, ["log"]))
        let result = { $0 * 2 } <£^> v
        #expect(result == .success(Writer(10, ["log"])))
    }

    @Test func validationTWriterApplyOperatorAccumulatesErrors() {
        let vf: Validation<[String], Writer<[String], @Sendable (Int) -> Int>> = .failure(["e1"])
        let va: Validation<[String], Writer<[String], Int>> = .failure(["e2"])
        #expect((vf <*> va) == .failure(["e1", "e2"]))
    }

    @Test func validationTWriterSeqRightOperatorAccumulatesErrors() {
        let lhs: Validation<[String], Writer<[String], Int>> = .failure(["e1"])
        let rhs: Validation<[String], Writer<[String], String>> = .failure(["e2"])
        #expect((lhs *> rhs) == .failure(["e1", "e2"]))
    }

    // MARK: - Helpers

    enum TestError: Error, Equatable { case boom }
}
