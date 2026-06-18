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

    // MARK: - Either<L, NonEmpty<A>> — flatMapT (monad)

    @Test func flatMapT_right_all_right() {
        let either: Either<String, NonEmpty<Int>> = .right(NonEmpty(head: 1, tail: [2]))
        let result = flatMapTEitherNonEmpty(either) { n in
            Either<String, NonEmpty<Int>?>.right(NonEmpty(head: n * 10))
        }
        #expect(result == .right(NonEmpty(head: 10, tail: [20])))
    }

    @Test func flatMapT_right_some_nil() {
        let either: Either<String, NonEmpty<Int>> = .right(NonEmpty(head: 1, tail: [2, 3]))
        let result = flatMapTEitherNonEmpty(either) { n -> Either<String, NonEmpty<Int>?> in
            n == 2 ? .right(nil) : .right(NonEmpty(head: n * 10))
        }
        #expect(result == .right(NonEmpty(head: 10, tail: [30])))
    }

    @Test func flatMapT_right_short_circuits_on_left() {
        let either: Either<String, NonEmpty<Int>> = .right(NonEmpty(head: 1, tail: [2, 3]))
        let result = flatMapTEitherNonEmpty(either) { n -> Either<String, NonEmpty<Int>?> in
            n == 2 ? .left("bad") : .right(NonEmpty(head: n * 10))
        }
        #expect(result == .left("bad"))
    }

    @Test func flatMapT_left_propagates() {
        let either: Either<String, NonEmpty<Int>> = .left("err")
        let result = flatMapTEitherNonEmpty(either) { n in
            Either<String, NonEmpty<Int>?>.right(NonEmpty(head: n * 10))
        }
        #expect(result == .left("err"))
    }

    @Test func bindT_curried() {
        let either: Either<String, NonEmpty<Int>> = .right(NonEmpty(head: 3))
        let bound = bindTEitherNonEmpty { n in Either<String, NonEmpty<Int>?>.right(NonEmpty(head: n + 1)) }(either)
        #expect(bound == .right(NonEmpty(head: 4)))
    }
}
