// SPDX-License-Identifier: Apache-2.0
import DataStructure
import Testing

@Suite struct EitherFoldableTests {
    // MARK: - foldMap

    @Test func foldMapRight() {
        let e: Either<String, Int> = .right(5)
        #expect(e.foldMap({ "\($0)" }) == "5")
    }

    @Test func foldMapLeftReturnsIdentity() {
        let e: Either<String, Int> = .left("error")
        #expect(e.foldMap({ "\($0)" }) == "")
    }

    @Test func foldMapCurried() {
        let fn = Either<String, Int>.foldMap({ "\($0)" })
        #expect(fn(.right(3)) == "3")
        #expect(fn(.left("x")) == "")
    }

    @Test func foldMapPointFree() {
        let values: [Either<String, Int>] = [.right(1), .left("err"), .right(2)]
        let result = values.map(Either<String, Int>.foldMap({ "\($0)" }))
        #expect(result == ["1", "", "2"])
    }

    // MARK: - toList

    @Test func toListRight() {
        let e: Either<String, Int> = .right(42)
        #expect(e.toList == [42])
    }

    @Test func toListLeft() {
        let e: Either<String, Int> = .left("error")
        #expect(e.toList == [])
    }
}
