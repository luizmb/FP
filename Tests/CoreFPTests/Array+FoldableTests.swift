// SPDX-License-Identifier: Apache-2.0
import CoreFP
import Testing

@Suite struct ArrayFoldableTests {
    // MARK: - foldLeft

    @Test func foldLeftSums() {
        let result = [Int].foldLeft(0, +)([1, 2, 3, 4])
        #expect(result == 10)
    }

    @Test func foldLeftIsLeftAssociative() {
        // (((0 - 1) - 2) - 3) = -6
        let result = [Int].foldLeft(0, -)([1, 2, 3])
        #expect(result == -6)
    }

    @Test func foldLeftOnEmpty() {
        let result = [Int].foldLeft(99, +)([])
        #expect(result == 99)
    }

    @Test func foldLeftBuildsString() {
        let result = [String].foldLeft("") { $0 + $1 }(["a", "b", "c"])
        #expect(result == "abc")
    }

    // MARK: - foldRight

    @Test func foldRightIsRightAssociative() {
        // 1 - (2 - (3 - 0)) = 2
        let result = [Int].foldRight({ $0 - $1 }, 0)([1, 2, 3])
        #expect(result == 2)
    }

    @Test func foldRightBuildsListInOrder() {
        let result = [Int].foldRight({ [$0] + $1 }, [])([1, 2, 3])
        #expect(result == [1, 2, 3])
    }

    @Test func foldRightOnEmpty() {
        let result = [Int].foldRight(+, 0)([])
        #expect(result == 0)
    }

    // MARK: - foldMap

    @Test func foldMapConcatenatesStrings() {
        let result = [Int].foldMap { "\($0)" }([1, 2, 3])
        #expect(result == "123")
    }

    @Test func foldMapOnEmpty() {
        let result = [String].foldMap(id)([])
        #expect(result == "")
    }

    @Test func foldMapPointFree() {
        let toStrings = [Int].foldMap { "\($0)" }
        #expect(toStrings([1, 2, 3]) == "123")
        #expect(toStrings([]) == "")
    }
}
