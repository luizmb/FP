// SPDX-License-Identifier: Apache-2.0
import CoreFP
import CoreFPOperators
import DataStructure
import DataStructureOperators
import Testing

/// Operator-syntax coverage for the "Validation-outer" transformer stacks:
/// `ValidationTArray`, `ValidationTEither`, `ValidationTNonEmpty`, `ValidationTOptional`,
/// `ValidationTReader`, `ValidationTResult`, `ValidationTStateful` and `ValidationTWriter`.
///
/// Validation is an accumulating Applicative, not a Monad: these stacks are applicative-only,
/// so there is no `>>-` here.
@Suite struct ValidationOuterTransformerOperatorsTests {
    // MARK: - ValidationTArray

    @Test func validationTArrayApplyOperatorAccumulatesErrors() {
        let vf = ValidationTArray<[String], @Sendable (Int) -> Int>(.failure(["e1"]))
        let va = ValidationTArray<[String], Int>(.failure(["e2"]))
        #expect((vf <*> va).rawValue == .failure(["e1", "e2"]))
    }

    @Test func validationTArraySeqRightOperatorAccumulatesErrors() {
        let lhs = ValidationTArray<[String], Int>(.failure(["e1"]))
        let rhs = ValidationTArray<[String], String>(.failure(["e2"]))
        #expect((lhs *> rhs).rawValue == .failure(["e1", "e2"]))
    }

    // MARK: - ValidationTEither

    @Test func validationTEitherApplyOperatorAccumulatesErrors() {
        let vf = ValidationTEither<[String], String, @Sendable (Int) -> Int>(.failure(["e1"]))
        let va = ValidationTEither<[String], String, Int>(.failure(["e2"]))
        #expect((vf <*> va).rawValue == .failure(["e1", "e2"]))
    }

    @Test func validationTEitherSeqLeftOperatorAccumulatesErrors() {
        let lhs = ValidationTEither<[String], String, Int>(.failure(["e1"]))
        let rhs = ValidationTEither<[String], String, String>(.failure(["e2"]))
        #expect((lhs <* rhs).rawValue == .failure(["e1", "e2"]))
    }

    // MARK: - ValidationTNonEmpty

    @Test func validationTNonEmptyApplyOperatorAccumulatesErrors() {
        let vf = ValidationTNonEmpty<[String], @Sendable (Int) -> Int>(.failure(["e1"]))
        let va = ValidationTNonEmpty<[String], Int>(.failure(["e2"]))
        let result = (vf <*> va).rawValue
        #expect(result.is(.failure), "Expected failure")
        if case let .failure(e) = result { #expect(e == ["e1", "e2"]) }
    }

    @Test func validationTNonEmptyApplyOperatorSuccessSuccess() {
        let increment: @Sendable (Int) -> Int = { $0 + 1 }
        let vf = ValidationTNonEmpty<[String], @Sendable (Int) -> Int>(.success(NonEmpty(head: increment)))
        let va = ValidationTNonEmpty<[String], Int>(.success(NonEmpty(head: 5, tail: [10])))
        #expect((vf <*> va).rawValue == .success(NonEmpty(head: 6, tail: [11])))
    }

    @Test func validationTNonEmptySeqRightOperator() {
        let lhs = ValidationTNonEmpty<[String], Int>(.success(NonEmpty(head: 1)))
        let rhs = ValidationTNonEmpty<[String], Int>(.success(NonEmpty(head: 10)))
        #expect((lhs *> rhs).rawValue == .success(NonEmpty(head: 10)))
    }

    @Test func validationTNonEmptySeqLeftOperator() {
        let lhs = ValidationTNonEmpty<[String], Int>(.success(NonEmpty(head: 1)))
        let rhs = ValidationTNonEmpty<[String], Int>(.success(NonEmpty(head: 10)))
        #expect((lhs <* rhs).rawValue == .success(NonEmpty(head: 1)))
    }

    // MARK: - ValidationTOptional

    @Test func validationTOptionalApplyOperatorAccumulatesErrors() {
        let vf = ValidationTOptional<[String], @Sendable (Int) -> Int>(.failure(["e1"]))
        let va = ValidationTOptional<[String], Int>(.failure(["e2"]))
        #expect((vf <*> va).rawValue == .failure(["e1", "e2"]))
    }

    @Test func validationTOptionalSeqRightOperatorAccumulatesErrors() {
        let lhs = ValidationTOptional<[String], Int>(.failure(["e1"]))
        let rhs = ValidationTOptional<[String], String>(.failure(["e2"]))
        #expect((lhs *> rhs).rawValue == .failure(["e1", "e2"]))
    }

    @Test func validationTOptionalMapOperators() {
        let stack = ValidationTOptional<[String], Int>(.success(5))
        #expect(({ $0 * 2 } <£> stack).rawValue == .success(10))
        #expect((stack <&> { $0 + 1 }).rawValue == .success(6))
        #expect((stack £> "x").rawValue == .success("x"))
        #expect(("y" <£ stack).rawValue == .success("y"))
    }

    // MARK: - ValidationTReader

    @Test func validationTReaderApplyOperatorAccumulatesErrors() {
        let vf = ValidationTReader<[String], String, @Sendable (Int) -> Int>(.failure(["e1"]))
        let va = ValidationTReader<[String], String, Int>(.failure(["e2"]))
        let result = (vf <*> va).rawValue
        #expect(result.is(.failure), "Expected failure")
        if case let .failure(e) = result { #expect(e == ["e1", "e2"]) }
    }

    @Test func validationTReaderSeqLeftOperatorAccumulatesErrors() {
        let lhs = ValidationTReader<[String], String, Int>(.failure(["e1"]))
        let rhs = ValidationTReader<[String], String, String>(.failure(["e2"]))
        let result = (lhs <* rhs).rawValue
        #expect(result.is(.failure), "Expected failure")
        if case let .failure(e) = result { #expect(e == ["e1", "e2"]) }
    }

    // MARK: - ValidationTResult

    @Test func validationTResultApplyOperatorAccumulatesErrors() {
        let vf = ValidationTResult<[String], TestError, @Sendable (Int) -> Int>(.failure(["e1"]))
        let va = ValidationTResult<[String], TestError, Int>(.failure(["e2"]))
        let result = (vf <*> va).rawValue
        #expect(result.is(.failure), "Expected failure")
        if case let .failure(e) = result { #expect(e == ["e1", "e2"]) }
    }

    @Test func validationTResultSeqRightOperatorAccumulatesErrors() {
        let lhs = ValidationTResult<[String], TestError, Int>(.failure(["e1"]))
        let rhs = ValidationTResult<[String], TestError, String>(.failure(["e2"]))
        let result = (lhs *> rhs).rawValue
        #expect(result.is(.failure), "Expected failure")
        if case let .failure(e) = result { #expect(e == ["e1", "e2"]) }
    }

    // MARK: - ValidationTStateful

    @Test func validationTStatefulApplyOperatorAccumulatesErrors() {
        let vf = ValidationTStateful<[String], Int, @Sendable (Int) -> Int>(.failure(["e1"]))
        let va = ValidationTStateful<[String], Int, Int>(.failure(["e2"]))
        let result = (vf <*> va).rawValue
        #expect(result.is(.failure), "Expected failure")
        if case let .failure(e) = result { #expect(e == ["e1", "e2"]) }
    }

    @Test func validationTStatefulSeqLeftOperatorAccumulatesErrors() {
        let lhs = ValidationTStateful<[String], Int, Int>(.failure(["e1"]))
        let rhs = ValidationTStateful<[String], Int, String>(.failure(["e2"]))
        let result = (lhs <* rhs).rawValue
        #expect(result.is(.failure), "Expected failure")
        if case let .failure(e) = result { #expect(e == ["e1", "e2"]) }
    }

    // MARK: - ValidationTWriter

    @Test func validationTWriterApplyOperatorAccumulatesErrors() {
        let vf = ValidationTWriter<[String], [String], @Sendable (Int) -> Int>(.failure(["e1"]))
        let va = ValidationTWriter<[String], [String], Int>(.failure(["e2"]))
        #expect((vf <*> va).rawValue == .failure(["e1", "e2"]))
    }

    @Test func validationTWriterSeqRightOperatorAccumulatesErrors() {
        let lhs = ValidationTWriter<[String], [String], Int>(.failure(["e1"]))
        let rhs = ValidationTWriter<[String], [String], String>(.failure(["e2"]))
        #expect((lhs *> rhs).rawValue == .failure(["e1", "e2"]))
    }

    // MARK: - Helpers

    enum TestError: Error, Equatable { case boom }
}
