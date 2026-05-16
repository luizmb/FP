import CoreFP
import Testing

@Suite struct ArrayCartesianTests {
    // MARK: - 2-ary cartesian

    @Test func cartesian2_basic() {
        let result = Array.cartesian([1, 3, 5], ["a", "b"])
        let expected: [(Int, String)] = [
            (1, "a"), (1, "b"),
            (3, "a"), (3, "b"),
            (5, "a"), (5, "b")
        ]
        #expect(result.count == expected.count)
        for (lhs, rhs) in zip(result, expected) {
            #expect(lhs.0 == rhs.0)
            #expect(lhs.1 == rhs.1)
        }
    }

    @Test func cartesian2_leftEmpty_returnsEmpty() {
        let result = Array.cartesian([Int](), ["a", "b"])
        #expect(result.isEmpty)
    }

    @Test func cartesian2_rightEmpty_returnsEmpty() {
        let result = Array.cartesian([1, 2], [String]())
        #expect(result.isEmpty)
    }

    @Test func cartesian2_size_isProduct() {
        let result = Array.cartesian([1, 2, 3, 4], [10, 20])
        #expect(result.count == 8)
    }

    // MARK: - 3-ary cartesian

    @Test func cartesian3_basic() {
        let result = Array.cartesian([1, 2], ["a"], [true, false])
        let expected: [(Int, String, Bool)] = [
            (1, "a", true), (1, "a", false),
            (2, "a", true), (2, "a", false)
        ]
        #expect(result.count == expected.count)
        for (lhs, rhs) in zip(result, expected) {
            #expect(lhs.0 == rhs.0)
            #expect(lhs.1 == rhs.1)
            #expect(lhs.2 == rhs.2)
        }
    }

    @Test func cartesian3_anyEmpty_returnsEmpty() {
        #expect(Array.cartesian([Int](), [1], [1]).isEmpty)
        #expect(Array.cartesian([1], [Int](), [1]).isEmpty)
        #expect(Array.cartesian([1], [1], [Int]()).isEmpty)
    }

    @Test func cartesian3_size_isProduct() {
        let result = Array.cartesian([1, 2, 3], ["a", "b"], [true, false])
        #expect(result.count == 12)
    }

    // MARK: - 4-ary cartesian

    @Test func cartesian4_basic() {
        let result = Array.cartesian([1], ["a", "b"], [true], [10, 20])
        let expected: [(Int, String, Bool, Int)] = [
            (1, "a", true, 10), (1, "a", true, 20),
            (1, "b", true, 10), (1, "b", true, 20)
        ]
        #expect(result.count == expected.count)
        for (lhs, rhs) in zip(result, expected) {
            #expect(lhs.0 == rhs.0)
            #expect(lhs.1 == rhs.1)
            #expect(lhs.2 == rhs.2)
            #expect(lhs.3 == rhs.3)
        }
    }

    @Test func cartesian4_size_isProduct() {
        let result = Array.cartesian([1, 2], [3, 4], [5, 6], [7, 8])
        #expect(result.count == 16)
    }

    @Test func cartesian4_anyEmpty_returnsEmpty() {
        #expect(Array.cartesian([Int](), [1], [1], [1]).isEmpty)
        #expect(Array.cartesian([1], [1], [1], [Int]()).isEmpty)
    }
}
