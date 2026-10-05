// SPDX-License-Identifier: Apache-2.0
import CoreFP
import CoreFPOperators
import DataStructure
import DataStructureOperators
import Testing

@Suite struct EitherTNonEmptyOperatorsTests {
    // MARK: - Applicative operators

    @Test func applyOperator_right_functions_right_values() {
        let increment: @Sendable (Int) -> Int = { $0 + 1 }
        let timesTen: @Sendable (Int) -> Int = { $0 * 10 }
        let functions: Either<String, NonEmpty<@Sendable (Int) -> Int>> = .right(
            NonEmpty(head: increment, tail: [timesTen])
        )
        let values: Either<String, NonEmpty<Int>> = .right(NonEmpty(head: 1, tail: [2]))
        let result = (functions.eitherT <*> values.eitherT).rawValue
        #expect(result == .right(NonEmpty(head: 2, tail: [3, 10, 20])))
    }

    @Test func applyOperator_left_functions_short_circuits() {
        let functions: Either<String, NonEmpty<@Sendable (Int) -> Int>> = .left("fnErr")
        let values: Either<String, NonEmpty<Int>> = .right(NonEmpty(head: 1, tail: [2]))
        let result = (functions.eitherT <*> values.eitherT).rawValue
        #expect(result == .left("fnErr"))
    }

    @Test func seqRightOperator_right_right() {
        let lhs: Either<String, NonEmpty<Int>> = .right(NonEmpty(head: 1, tail: [2]))
        let rhs: Either<String, NonEmpty<Int>> = .right(NonEmpty(head: 10))
        let result = (lhs.eitherT *> rhs.eitherT).rawValue
        #expect(result == .right(NonEmpty(head: 10, tail: [10])))
    }

    @Test func seqRightOperator_left_short_circuits() {
        let lhs: Either<String, NonEmpty<Int>> = .left("err")
        let rhs: Either<String, NonEmpty<Int>> = .right(NonEmpty(head: 10))
        let result = (lhs.eitherT *> rhs.eitherT).rawValue
        #expect(result == .left("err"))
    }

    @Test func seqLeftOperator_right_right() {
        let lhs: Either<String, NonEmpty<Int>> = .right(NonEmpty(head: 1, tail: [2]))
        let rhs: Either<String, NonEmpty<Int>> = .right(NonEmpty(head: 10))
        let result = (lhs.eitherT <* rhs.eitherT).rawValue
        #expect(result == .right(NonEmpty(head: 1, tail: [2])))
    }

    @Test func seqLeftOperator_left_short_circuits() {
        let lhs: Either<String, NonEmpty<Int>> = .left("err")
        let rhs: Either<String, NonEmpty<Int>> = .right(NonEmpty(head: 10))
        let result = (lhs.eitherT <* rhs.eitherT).rawValue
        #expect(result == .left("err"))
    }
}
