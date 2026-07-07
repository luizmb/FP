// SPDX-License-Identifier: Apache-2.0
import CoreFPOperators
import DataStructure
import DataStructureOperators
import Testing

@Suite struct ValidationTNonEmptyOperatorsTests {
    @Test func fmapOperator_forward_success() {
        let v: Validation<String, NonEmpty<Int>> = .success(NonEmpty(head: 1, tail: [2, 3]))
        let result = { $0 * 10 } <£^> v
        #expect(result == .success(NonEmpty(head: 10, tail: [20, 30])))
    }

    @Test func fmapOperator_forward_failure() {
        let v: Validation<String, NonEmpty<Int>> = .failure("err")
        let result = { $0 * 10 } <£^> v
        #expect(result == .failure("err"))
    }

    @Test func fmapOperator_flipped() {
        let v: Validation<String, NonEmpty<Int>> = .success(NonEmpty(head: 5))
        let result = v <&^> { $0 + 1 }
        #expect(result == .success(NonEmpty(head: 6)))
    }

    // MARK: - Applicative: <*> / *> / <*

    @Test func applyOperator_accumulatesErrors() {
        let vf: Validation<[String], NonEmpty<@Sendable (Int) -> Int>> = .failure(["e1"])
        let va: Validation<[String], NonEmpty<Int>> = .failure(["e2"])
        let result = vf <*> va
        #expect(result.is(.failure), "Expected failure")
        if case let .failure(e) = result { #expect(e == ["e1", "e2"]) }
    }

    @Test func applyOperator_successSuccess() {
        let increment: @Sendable (Int) -> Int = { $0 + 1 }
        let vf: Validation<[String], NonEmpty<@Sendable (Int) -> Int>> = .success(NonEmpty(head: increment))
        let va: Validation<[String], NonEmpty<Int>> = .success(NonEmpty(head: 5, tail: [10]))
        let result = vf <*> va
        #expect(result == .success(NonEmpty(head: 6, tail: [11])))
    }

    @Test func seqRightOperator() {
        let lhs: Validation<[String], NonEmpty<Int>> = .success(NonEmpty(head: 1))
        let rhs: Validation<[String], NonEmpty<Int>> = .success(NonEmpty(head: 10))
        #expect((lhs *> rhs) == .success(NonEmpty(head: 10)))
    }

    @Test func seqLeftOperator() {
        let lhs: Validation<[String], NonEmpty<Int>> = .success(NonEmpty(head: 1))
        let rhs: Validation<[String], NonEmpty<Int>> = .success(NonEmpty(head: 10))
        #expect((lhs <* rhs) == .success(NonEmpty(head: 1)))
    }
}
