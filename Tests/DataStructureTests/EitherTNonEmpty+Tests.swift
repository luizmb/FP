// SPDX-License-Identifier: Apache-2.0
import DataStructure
import Testing

@Suite struct EitherTNonEmptyTests {
    // MARK: - Either<L, NonEmpty<A>> — map (functor)

    @Test func map_right() {
        let either: Either<String, NonEmpty<Int>> = .right(NonEmpty(head: 1, tail: [2, 3]))
        let result = either.eitherT.map { $0 * 10 }.rawValue
        #expect(result == .right(NonEmpty(head: 10, tail: [20, 30])))
    }

    @Test func map_left_propagates() {
        let either: Either<String, NonEmpty<Int>> = .left("err")
        let result = either.eitherT.map { $0 * 10 }.rawValue
        #expect(result == .left("err"))
    }

    @Test func fmap_curried() {
        let either: Either<String, NonEmpty<Int>> = .right(NonEmpty(head: 5))
        let mapped = EitherTNonEmpty<String, Int>.fmap { $0 + 1 }(either.eitherT).rawValue
        #expect(mapped == .right(NonEmpty(head: 6)))
    }
}
