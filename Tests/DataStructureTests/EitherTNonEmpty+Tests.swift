// SPDX-License-Identifier: Apache-2.0
import DataStructure
import Testing

@Suite struct EitherTNonEmptyTests {
    // MARK: - Either<L, NonEmpty<A>> — mapT (functor)

    @Test func mapT_right() {
        let either: Either<String, NonEmpty<Int>> = .right(NonEmpty(head: 1, tail: [2, 3]))
        let result = mapTEitherNonEmpty({ $0 * 10 }, either)
        #expect(result == .right(NonEmpty(head: 10, tail: [20, 30])))
    }

    @Test func mapT_left_propagates() {
        let either: Either<String, NonEmpty<Int>> = .left("err")
        let result = mapTEitherNonEmpty({ $0 * 10 }, either)
        #expect(result == .left("err"))
    }

    @Test func fmapT_curried() {
        let either: Either<String, NonEmpty<Int>> = .right(NonEmpty(head: 5))
        let mapped = fmapTEitherNonEmpty { $0 + 1 }(either)
        #expect(mapped == .right(NonEmpty(head: 6)))
    }
}
