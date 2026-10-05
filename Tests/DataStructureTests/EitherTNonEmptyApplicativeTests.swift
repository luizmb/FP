// SPDX-License-Identifier: Apache-2.0
import CoreFP
import DataStructure
import Testing

@Suite struct EitherTNonEmptyApplicativeTests {
    // MARK: - apply

    @Test func apply_right_functions_right_values() {
        let increment: @Sendable (Int) -> Int = { $0 + 1 }
        let timesTen: @Sendable (Int) -> Int = { $0 * 10 }
        let functions: Either<String, NonEmpty<@Sendable (Int) -> Int>> = .right(
            NonEmpty(head: increment, tail: [timesTen])
        )
        let values: Either<String, NonEmpty<Int>> = .right(NonEmpty(head: 1, tail: [2]))
        let result = EitherTNonEmpty.apply(functions.eitherT, values.eitherT).rawValue
        #expect(result == .right(NonEmpty(head: 2, tail: [3, 10, 20])))
    }

    @Test func apply_left_functions_short_circuits() {
        let functions: Either<String, NonEmpty<@Sendable (Int) -> Int>> = .left("fnErr")
        let values: Either<String, NonEmpty<Int>> = .right(NonEmpty(head: 1, tail: [2]))
        let result = EitherTNonEmpty.apply(functions.eitherT, values.eitherT).rawValue
        #expect(result == .left("fnErr"))
    }

    @Test func apply_left_values_short_circuits() {
        let increment: @Sendable (Int) -> Int = { $0 + 1 }
        let functions: Either<String, NonEmpty<@Sendable (Int) -> Int>> = .right(NonEmpty(head: increment))
        let values: Either<String, NonEmpty<Int>> = .left("valErr")
        let result = EitherTNonEmpty.apply(functions.eitherT, values.eitherT).rawValue
        #expect(result == .left("valErr"))
    }

    // MARK: - liftA2

    @Test func liftA2_right_right() {
        let lhs: Either<String, NonEmpty<Int>> = .right(NonEmpty(head: 1, tail: [2]))
        let rhs: Either<String, NonEmpty<Int>> = .right(NonEmpty(head: 10, tail: [20]))
        let result = EitherTNonEmpty<String, Int>.liftA2 { (a: Int, b: Int) in a + b }(lhs.eitherT, rhs.eitherT).rawValue
        #expect(result == .right(NonEmpty(head: 11, tail: [21, 12, 22])))
    }

    @Test func liftA2_left_propagates() {
        let lhs: Either<String, NonEmpty<Int>> = .left("err")
        let rhs: Either<String, NonEmpty<Int>> = .right(NonEmpty(head: 10))
        let result = EitherTNonEmpty<String, Int>.liftA2 { (a: Int, b: Int) in a + b }(lhs.eitherT, rhs.eitherT).rawValue
        #expect(result == .left("err"))
    }

    // MARK: - seqRight / seqLeft

    @Test func seqRight_right_right() {
        let lhs: Either<String, NonEmpty<Int>> = .right(NonEmpty(head: 1, tail: [2]))
        let rhs: Either<String, NonEmpty<Int>> = .right(NonEmpty(head: 10))
        let result = lhs.eitherT.seqRight(rhs.eitherT).rawValue
        #expect(result == .right(NonEmpty(head: 10, tail: [10])))
    }

    @Test func seqRight_left_short_circuits() {
        let lhs: Either<String, NonEmpty<Int>> = .left("err")
        let rhs: Either<String, NonEmpty<Int>> = .right(NonEmpty(head: 10))
        let result = lhs.eitherT.seqRight(rhs.eitherT).rawValue
        #expect(result == .left("err"))
    }

    @Test func seqLeft_right_right() {
        let lhs: Either<String, NonEmpty<Int>> = .right(NonEmpty(head: 1, tail: [2]))
        let rhs: Either<String, NonEmpty<Int>> = .right(NonEmpty(head: 10))
        let result = lhs.eitherT.seqLeft(rhs.eitherT).rawValue
        #expect(result == .right(NonEmpty(head: 1, tail: [2])))
    }

    @Test func seqLeft_left_short_circuits() {
        let lhs: Either<String, NonEmpty<Int>> = .left("err")
        let rhs: Either<String, NonEmpty<Int>> = .right(NonEmpty(head: 10))
        let result = lhs.eitherT.seqLeft(rhs.eitherT).rawValue
        #expect(result == .left("err"))
    }
}
