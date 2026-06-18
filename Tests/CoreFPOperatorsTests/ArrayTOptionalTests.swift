// SPDX-License-Identifier: Apache-2.0
@testable import CoreFP
@testable import CoreFPOperators
import Testing

@Suite struct ArrayTOptionalTests {
    // MARK: - Functor

    @Test func mapTAllPresent() {
        let arr: [Int?] = [1, 2, 3]
        let result = arr.mapT { $0 * 2 }
        #expect(result == [2, 4, 6])
    }

    @Test func mapTWithNils() {
        let arr: [Int?] = [1, nil, 3]
        let result = arr.mapT { $0 * 2 }
        #expect(result == [2, nil, 6])
    }

    @Test func mapTAllNils() {
        let arr: [Int?] = [nil, nil]
        let result = arr.mapT { $0 * 2 }
        #expect(result == [nil, nil])
    }

    @Test func fmapOperator() {
        let arr: [Int?] = [1, nil, 3]
        let result = { $0 * 2 } <£^> arr
        #expect(result == [2, nil, 6])
    }

    @Test func flippedFmapOperator() {
        let arr: [Int?] = [1, nil, 3]
        let result = arr <&^> { $0 * 2 }
        #expect(result == [2, nil, 6])
    }

    // MARK: - Applicative

    @Test func liftA2CartesianProduct() {
        let a: [Int?] = [1, 2]
        let b: [Int?] = [10, 20]
        let result = liftA2ArrayOptional(+)(a, b)
        #expect(result == [11, 21, 12, 22])
    }

    @Test func liftA2WithNils() {
        let a: [Int?] = [1, nil]
        let b: [Int?] = [10]
        let result = liftA2ArrayOptional(+)(a, b)
        #expect(result == [11, nil])
    }

    @Test func seqRightCartesianProduct() {
        let a: [Int?] = [1, nil]
        let b: [String?] = ["x", nil]
        let result = a *> b
        // Cartesian: (1,x)=x, (1,nil)=nil, (nil,x)=nil, (nil,nil)=nil
        #expect(result == ["x", nil, nil, nil])
    }

    @Test func seqLeftCartesianProduct() {
        let a: [Int?] = [1, nil]
        let b: [String?] = ["x"]
        let result = a <* b
        // (1,"x")=1, (nil,"x")=nil
        #expect(result == [1, nil])
    }

    // MARK: - Monad

    @Test func flatMapTAllPresent() {
        let arr: [Int?] = [1, 2, 3]
        let result = arr.flatMapT { n in [n, n * 10] as [Int?] }
        #expect(result == [1, 10, 2, 20, 3, 30])
    }

    @Test func flatMapTNilPropagates() {
        let arr: [Int?] = [1, nil, 3]
        let result = arr.flatMapT { n in [n * 2] as [Int?] }
        // nil element → [nil]
        #expect(result == [2, nil, 6])
    }

    @Test func flatMapTEmpty() {
        let arr: [Int?] = []
        let result = arr.flatMapT { n in [n * 2] as [Int?] }
        #expect(result == [])
    }

    @Test func bindOperator() {
        let arr: [Int?] = [1, 2]
        let result = arr >>- { n in [n, n + 100] as [Int?] }
        #expect(result == [1, 101, 2, 102])
    }

    @Test func kleisliOperator() {
        let f: @Sendable (Int) -> [Int?] = { n in [n, n * 2] }
        let g: @Sendable (Int) -> [String?] = { n in ["\(n)"] }
        let h = f >=> g
        #expect(h(3) == ["3", "6"])
    }
}
