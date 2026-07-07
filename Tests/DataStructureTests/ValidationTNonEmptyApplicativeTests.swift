// SPDX-License-Identifier: Apache-2.0
import DataStructure
import Testing

// Validation is an accumulating Applicative, not a Monad — there is no `flatMapT` for
// ValidationTNonEmpty and none is referenced here.
@Suite struct ValidationTNonEmptyApplicativeTests {
    // MARK: - apply

    @Test func applyAccumulatesErrors() {
        let vf: Validation<[String], NonEmpty<@Sendable (Int) -> Int>> = .failure(["e1"])
        let va: Validation<[String], NonEmpty<Int>> = .failure(["e2"])
        let result = applyValidationNonEmpty(vf, va)
        #expect(result.is(.failure), "Expected failure")
        if case let .failure(e) = result { #expect(e == ["e1", "e2"]) }
    }

    @Test func applySuccessSuccess() {
        let increment: @Sendable (Int) -> Int = { $0 + 1 }
        let vf: Validation<[String], NonEmpty<@Sendable (Int) -> Int>> = .success(NonEmpty(head: increment))
        let va: Validation<[String], NonEmpty<Int>> = .success(NonEmpty(head: 5, tail: [10]))
        let result = applyValidationNonEmpty(vf, va)
        #expect(result == .success(NonEmpty(head: 6, tail: [11])))
    }

    // MARK: - liftA2

    @Test func liftA2AccumulatesErrors() {
        let va: Validation<[String], NonEmpty<Int>> = .failure(["e1"])
        let vb: Validation<[String], NonEmpty<Int>> = .failure(["e2"])
        let result = liftA2ValidationNonEmpty { (a: Int, b: Int) in a + b }(va, vb)
        #expect(result.is(.failure), "Expected failure")
        if case let .failure(e) = result { #expect(e == ["e1", "e2"]) }
    }

    @Test func liftA2SuccessSuccess() {
        let va: Validation<[String], NonEmpty<Int>> = .success(NonEmpty(head: 1))
        let vb: Validation<[String], NonEmpty<Int>> = .success(NonEmpty(head: 10))
        let result = liftA2ValidationNonEmpty { (a: Int, b: Int) in a + b }(va, vb)
        #expect(result == .success(NonEmpty(head: 11)))
    }

    // MARK: - seqRight / seqLeft

    @Test func seqRightAccumulatesErrors() {
        let lhs: Validation<[String], NonEmpty<Int>> = .failure(["e1"])
        let rhs: Validation<[String], NonEmpty<Int>> = .failure(["e2"])
        let result = seqRightValidationNonEmpty(lhs, rhs)
        #expect(result.is(.failure), "Expected failure")
        if case let .failure(e) = result { #expect(e == ["e1", "e2"]) }
    }

    @Test func seqRightSuccessSuccess() {
        let lhs: Validation<[String], NonEmpty<Int>> = .success(NonEmpty(head: 1))
        let rhs: Validation<[String], NonEmpty<Int>> = .success(NonEmpty(head: 10))
        #expect(seqRightValidationNonEmpty(lhs, rhs) == .success(NonEmpty(head: 10)))
    }

    @Test func seqLeftSuccessSuccess() {
        let lhs: Validation<[String], NonEmpty<Int>> = .success(NonEmpty(head: 1))
        let rhs: Validation<[String], NonEmpty<Int>> = .success(NonEmpty(head: 10))
        #expect(seqLeftValidationNonEmpty(lhs, rhs) == .success(NonEmpty(head: 1)))
    }
}
