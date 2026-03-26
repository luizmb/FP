import Testing
@testable import CoreFP
@testable import CoreFPOperators

@Suite struct OptionalTArrayTests {

    // MARK: - Functor

    @Test func mapTSome() {
        let opt: [Int]? = [1, 2, 3]
        let result = opt.mapT { $0 * 2 }
        #expect(result == [2, 4, 6])
    }

    @Test func mapTNone() {
        let opt: [Int]? = nil
        let result = opt.mapT { $0 * 2 }
        #expect(result == nil)
    }

    @Test func fmapOperatorSome() {
        let opt: [Int]? = [1, 2, 3]
        let result = { $0 * 2 } <£^> opt
        #expect(result == [2, 4, 6])
    }

    @Test func fmapOperatorNone() {
        let opt: [Int]? = nil
        let result = { $0 * 2 } <£^> opt
        #expect(result == nil)
    }

    @Test func flippedFmapOperatorSome() {
        let opt: [Int]? = [1, 2, 3]
        let result = opt <&^> { $0 * 2 }
        #expect(result == [2, 4, 6])
    }

    @Test func flippedFmapOperatorNone() {
        let opt: [Int]? = nil
        let result = opt <&^> { $0 * 2 }
        #expect(result == nil)
    }

    // MARK: - Applicative

    @Test func liftA2BothPresent() {
        let a: [Int]? = [1, 2]
        let b: [Int]? = [10, 20]
        let result = liftA2OptionalArray(+)(a, b)
        #expect(result == [11, 21, 12, 22])
    }

    @Test func liftA2LeftNil() {
        let a: [Int]? = nil
        let b: [Int]? = [10, 20]
        let result = liftA2OptionalArray(+)(a, b)
        #expect(result == nil)
    }

    @Test func liftA2RightNil() {
        let a: [Int]? = [1, 2]
        let b: [Int]? = nil
        let result = liftA2OptionalArray(+)(a, b)
        #expect(result == nil)
    }

    @Test func seqRightBothPresent() {
        let a: [Int]? = [1, 2]
        let b: [String]? = ["x", "y"]
        let result = a *> b
        #expect(result == ["x", "y"])
    }

    @Test func seqRightLeftNil() {
        let a: [Int]? = nil
        let b: [String]? = ["x"]
        let result = a *> b
        #expect(result == nil)
    }

    @Test func seqLeftBothPresent() {
        let a: [Int]? = [1, 2]
        let b: [String]? = ["x", "y"]
        let result = a <* b
        #expect(result == [1, 2])
    }

    // MARK: - Monad

    @Test func flatMapTSomeAllSucceed() {
        let opt: [Int]? = [1, 2, 3]
        let result = opt.flatMapT { n in [n, n * 10] as [Int]? }
        #expect(result == [1, 10, 2, 20, 3, 30])
    }

    @Test func flatMapTSomeOneNil() {
        let opt: [Int]? = [1, 2, 3]
        let result = opt.flatMapT { n -> [Int]? in
            n == 2 ? nil : [n, n * 10]
        }
        #expect(result == nil)
    }

    @Test func flatMapTNone() {
        let opt: [Int]? = nil
        let result = opt.flatMapT { n in [n * 2] as [Int]? }
        #expect(result == nil)
    }

    @Test func flatMapTEmpty() {
        let opt: [Int]? = []
        let result = opt.flatMapT { n in [n * 2] as [Int]? }
        #expect(result == [])
    }

    @Test func bindOperator() {
        let opt: [Int]? = [1, 2]
        let result = opt >>- { n in [n, n + 100] as [Int]? }
        #expect(result == [1, 101, 2, 102])
    }

    @Test func kleisliOperator() {
        let f: (Int) -> [Int]? = { n in [n, n * 2] }
        let g: (Int) -> [String]? = { n in ["\(n)"] }
        let h = f >=> g
        #expect(h(3) == ["3", "6"])
    }
}
