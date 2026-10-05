// SPDX-License-Identifier: Apache-2.0
import DataStructure
import Testing

@Suite struct NonEmptyTEitherTests {
    // MARK: - NonEmptyTEither — map

    @Test func map_right() {
        let ne = NonEmpty<Either<String, Int>>(head: .right(1), tail: [.right(2), .right(3)])
        let result = ne.nonEmptyT.map { $0 * 10 }.rawValue
        #expect(result.toArray == [.right(10), .right(20), .right(30)])
    }

    @Test func map_left_propagates() {
        let ne = NonEmpty<Either<String, Int>>(
            head: .right(1), tail: [.left("err"), .right(3)]
        )
        let result = ne.nonEmptyT.map { $0 * 10 }.rawValue
        #expect(result.toArray == [.right(10), .left("err"), .right(30)])
    }

    @Test func map_allLeft() {
        let ne = NonEmpty<Either<String, Int>>(head: .left("a"), tail: [.left("b")])
        let result = ne.nonEmptyT.map { $0 * 10 }.rawValue
        #expect(result.toArray == [.left("a"), .left("b")])
    }

    @Test func fmap_curried() {
        let ne = NonEmpty<Either<String, Int>>(head: .right(5))
        let mapped = NonEmptyTEither<String, Int>.fmap { $0 + 1 }(ne.nonEmptyT).rawValue
        #expect(mapped.toArray == [.right(6)])
    }

    // MARK: - NonEmptyTEither — flatMap

    @Test func flatMap_right_expands() {
        let ne = NonEmpty<Either<String, Int>>(head: .right(1), tail: [.right(2)])
        let result = ne.nonEmptyT.flatMap { n in
            NonEmptyTEither(NonEmpty<Either<String, Int>>(head: .right(n), tail: [.right(n * 10)]))
        }.rawValue
        #expect(result.toArray == [.right(1), .right(10), .right(2), .right(20)])
    }

    @Test func flatMap_left_propagates_as_singleton() {
        let ne = NonEmpty<Either<String, Int>>(head: .left("err"), tail: [.right(2)])
        let result = ne.nonEmptyT.flatMap { n in
            NonEmptyTEither(NonEmpty<Either<String, Int>>(head: .right(n * 10)))
        }.rawValue
        #expect(result.toArray == [.left("err"), .right(20)])
    }

    @Test func bind_curried() {
        let ne = NonEmpty<Either<String, Int>>(head: .right(3))
        let bound = NonEmptyTEither<String, Int>.bind { n in
            NonEmptyTEither(NonEmpty<Either<String, Int>>(head: .right(n + 1)))
        }(ne.nonEmptyT).rawValue
        #expect(bound.toArray == [.right(4)])
    }
}
