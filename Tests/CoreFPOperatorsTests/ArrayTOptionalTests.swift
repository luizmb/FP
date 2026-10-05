// SPDX-License-Identifier: Apache-2.0
import CoreFP
import CoreFPOperators
import Testing

@Suite struct ArrayTOptionalTests {
    private let add: @Sendable (Int) -> @Sendable (Int) -> Int = { x in { y in x + y } }

    // MARK: - Functor

    @Test func mapAllPresent() {
        let arr: [Int?] = [1, 2, 3]
        let result = { $0 * 2 } <£> arr.arrayT
        #expect(result.rawValue == [2, 4, 6])
    }

    @Test func mapWithNils() {
        let arr: [Int?] = [1, nil, 3]
        let result = arr.arrayT <&> { $0 * 2 }
        #expect(result.rawValue == [2, nil, 6])
    }

    @Test func mapAllNils() {
        let arr: [Int?] = [nil, nil]
        let result = { $0 * 2 } <£> arr.arrayT
        #expect(result.rawValue == [nil, nil])
    }

    // MARK: - Applicative

    @Test func liftA2CartesianProduct() {
        let a: [Int?] = [1, 2]
        let b: [Int?] = [10, 20]
        let result = add <£> a.arrayT <*> b.arrayT
        #expect(result.rawValue == [11, 21, 12, 22])
    }

    @Test func liftA2WithNils() {
        let a: [Int?] = [1, nil]
        let b: [Int?] = [10]
        let result = add <£> a.arrayT <*> b.arrayT
        #expect(result.rawValue == [11, nil])
    }

    @Test func seqRightCartesianProduct() {
        let a: [Int?] = [1, nil]
        let b: [String?] = ["x", nil]
        let result = a.arrayT *> b.arrayT
        // MaybeT []: 1 >>= const b = [x, nil]; nil short-circuits to [nil]
        #expect(result.rawValue == ["x", nil, nil])
    }

    @Test func seqLeftCartesianProduct() {
        let a: [Int?] = [1, nil]
        let b: [String?] = ["x"]
        let result = a.arrayT <* b.arrayT
        // (1,"x")=1, (nil,"x")=nil
        #expect(result.rawValue == [1, nil])
    }

    // MARK: - Monad

    @Test func bindAllPresent() {
        let arr: [Int?] = [1, 2, 3]
        let result = arr.arrayT >>- { n in ArrayTOptional([n, n * 10]) }
        #expect(result.rawValue == [1, 10, 2, 20, 3, 30])
    }

    @Test func bindNilPropagates() {
        let arr: [Int?] = [1, nil, 3]
        let result = arr.arrayT >>- { n in ArrayTOptional([n * 2]) }
        // nil element → [nil]
        #expect(result.rawValue == [2, nil, 6])
    }

    @Test func bindEmpty() {
        let arr: [Int?] = []
        let result = { n in ArrayTOptional([n * 2]) } -<< arr.arrayT
        #expect(result.rawValue == [])
    }

    @Test func bindOperator() {
        let arr: [Int?] = [1, 2]
        let result = arr.arrayT >>- { n in ArrayTOptional([n, n + 100]) }
        #expect(result.rawValue == [1, 101, 2, 102])
    }

    @Test func kleisliOperator() {
        let f: @Sendable (Int) -> ArrayTOptional<Int> = { n in ArrayTOptional([n, n * 2]) }
        let g: @Sendable (Int) -> ArrayTOptional<String> = { n in ArrayTOptional(["\(n)"]) }
        let h = f >=> g
        #expect(h(3).rawValue == ["3", "6"])
        #expect((g <=< f)(3).rawValue == ["3", "6"])
    }
}
