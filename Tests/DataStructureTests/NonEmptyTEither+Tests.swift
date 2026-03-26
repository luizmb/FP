import DataStructure
import Testing
import CoreFP

@Suite struct NonEmptyTEitherTests {

    // MARK: - NonEmpty<Either<L, A>> — mapT

    @Test func mapT_right() {
        let ne = NonEmpty<Either<String, Int>>(head: .right(1), tail: [.right(2), .right(3)])
        let result = ne.mapT { $0 * 10 }
        #expect(result.toArray == [.right(10), .right(20), .right(30)])
    }

    @Test func mapT_left_propagates() {
        let ne = NonEmpty<Either<String, Int>>(
            head: .right(1), tail: [.left("err"), .right(3)]
        )
        let result = ne.mapT { $0 * 10 }
        #expect(result.toArray == [.right(10), .left("err"), .right(30)])
    }

    @Test func mapT_allLeft() {
        let ne = NonEmpty<Either<String, Int>>(head: .left("a"), tail: [.left("b")])
        let result = ne.mapT { $0 * 10 }
        #expect(result.toArray == [.left("a"), .left("b")])
    }

    @Test func fmapT_curried() {
        let ne = NonEmpty<Either<String, Int>>(head: .right(5))
        let mapped = NonEmpty<Either<String, Int>>.fmapT({ $0 + 1 })(ne)
        #expect(mapped.toArray == [.right(6)])
    }

    // MARK: - NonEmpty<Either<L, A>> — flatMapT

    @Test func flatMapT_right_expands() {
        let ne = NonEmpty<Either<String, Int>>(head: .right(1), tail: [.right(2)])
        let result = ne.flatMapT { n in
            NonEmpty<Either<String, Int>>(head: .right(n), tail: [.right(n * 10)])
        }
        #expect(result.toArray == [.right(1), .right(10), .right(2), .right(20)])
    }

    @Test func flatMapT_left_propagates_as_singleton() {
        let ne = NonEmpty<Either<String, Int>>(head: .left("err"), tail: [.right(2)])
        let result = ne.flatMapT { n in
            NonEmpty<Either<String, Int>>(head: .right(n * 10))
        }
        #expect(result.toArray == [.left("err"), .right(20)])
    }

    @Test func bindT_curried() {
        let ne = NonEmpty<Either<String, Int>>(head: .right(3))
        let bound = NonEmpty<Either<String, Int>>.bindT({ n in
            NonEmpty<Either<String, Int>>(head: .right(n + 1))
        })(ne)
        #expect(bound.toArray == [.right(4)])
    }
}
