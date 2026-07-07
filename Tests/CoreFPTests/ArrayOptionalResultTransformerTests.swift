// SPDX-License-Identifier: Apache-2.0
@testable import CoreFP

// swiftlint:disable discouraged_optional_collection
import Testing

@Suite struct ArrayOptionalResultTransformerTests {
    private enum Err: Error, Equatable { case fail }

    // MARK: - ArrayTOptional: Functor

    @Test func arrayTOptionalMapTAllPresent() {
        let arr: [Int?] = [1, 2, 3]
        let result = arr.mapT { $0 * 2 }
        #expect(result == [2, 4, 6])
    }

    @Test func arrayTOptionalMapTWithNils() {
        let arr: [Int?] = [1, nil, 3]
        let result = arr.mapT { $0 * 2 }
        #expect(result == [2, nil, 6])
    }

    @Test func arrayTOptionalFmapTStatic() {
        let arr: [Int?] = [1, nil, 3]
        let result = [Int?].fmapT { (n: Int) in n * 2 }(arr)
        #expect(result == [2, nil, 6])
    }

    // MARK: - ArrayTOptional: Applicative

    @Test func arrayTOptionalApply() {
        let fns: [(@Sendable (Int) -> Int)?] = [{ $0 + 1 }, nil]
        let values: [Int?] = [10, 20]
        let result = applyArrayOptional(fns, values)
        #expect(result == [11, 21, nil, nil])
    }

    @Test func arrayTOptionalLiftA2CartesianProduct() {
        let a: [Int?] = [1, 2]
        let b: [Int?] = [10, 20]
        let result = liftA2ArrayOptional(+)(a, b)
        #expect(result == [11, 21, 12, 22])
    }

    @Test func arrayTOptionalLiftA2WithNils() {
        let a: [Int?] = [1, nil]
        let b: [Int?] = [10]
        let result = liftA2ArrayOptional(+)(a, b)
        #expect(result == [11, nil])
    }

    @Test func arrayTOptionalSeqRight() {
        let a: [Int?] = [1, nil]
        let b: [String?] = ["x", nil]
        let result = seqRightArrayOptional(a, b)
        #expect(result == ["x", nil, nil, nil])
    }

    @Test func arrayTOptionalSeqLeft() {
        let a: [Int?] = [1, nil]
        let b: [String?] = ["x"]
        let result = seqLeftArrayOptional(a, b)
        #expect(result == [1, nil])
    }

    // MARK: - ArrayTOptional: Monad

    @Test func arrayTOptionalFlatMapTAllPresent() {
        let arr: [Int?] = [1, 2, 3]
        let result = arr.flatMapT { n in [n, n * 10] as [Int?] }
        #expect(result == [1, 10, 2, 20, 3, 30])
    }

    @Test func arrayTOptionalFlatMapTNilPropagates() {
        let arr: [Int?] = [1, nil, 3]
        let result = arr.flatMapT { n in [n * 2] as [Int?] }
        #expect(result == [2, nil, 6])
    }

    @Test func arrayTOptionalFlatMapTEmpty() {
        let arr: [Int?] = []
        let result = arr.flatMapT { n in [n * 2] as [Int?] }
        #expect(result == [])
    }

    @Test func arrayTOptionalBindTStatic() {
        let arr: [Int?] = [1, 2]
        let result = [Int?].bindT { (n: Int) in [n, n + 100] as [Int?] }(arr)
        #expect(result == [1, 101, 2, 102])
    }

    // MARK: - ArrayTResult: Functor

    @Test func arrayTResultMapTAllSuccess() throws {
        let arr: [Result<Int, Err>] = [.success(1), .success(2), .success(3)]
        let result = arr.mapT { $0 * 2 }
        #expect(try result.map { try $0.get() } == [2, 4, 6])
    }

    @Test func arrayTResultMapTWithFailure() {
        let arr: [Result<Int, Err>] = [.success(1), .failure(.fail), .success(3)]
        let result = arr.mapT { $0 * 2 }
        #expect(result == [.success(2), .failure(.fail), .success(6)])
    }

    @Test func arrayTResultFmapTStatic() {
        let arr: [Result<Int, Err>] = [.success(1), .failure(.fail)]
        let result = [Result<Int, Err>].fmapT { (n: Int) in n * 2 }(arr)
        #expect(result == [.success(2), .failure(.fail)])
    }

    // MARK: - ArrayTResult: Applicative

    @Test func arrayTResultApply() {
        let fns: [Result<@Sendable (Int) -> Int, Err>] = [.success { $0 + 1 }, .failure(.fail)]
        let values: [Result<Int, Err>] = [.success(10)]
        let result = applyArrayResult(fns, values)
        #expect(result == [.success(11), .failure(.fail)])
    }

    @Test func arrayTResultLiftA2CartesianProduct() {
        let a: [Result<Int, Err>] = [.success(1), .success(2)]
        let b: [Result<Int, Err>] = [.success(10), .success(20)]
        let result = liftA2ArrayResult(+)(a, b)
        #expect(result == [.success(11), .success(21), .success(12), .success(22)])
    }

    @Test func arrayTResultLiftA2WithFailure() {
        let a: [Result<Int, Err>] = [.success(1), .failure(.fail)]
        let b: [Result<Int, Err>] = [.success(10)]
        let result = liftA2ArrayResult(+)(a, b)
        #expect(result == [.success(11), .failure(.fail)])
    }

    @Test func arrayTResultSeqRight() {
        let a: [Result<Int, Err>] = [.success(1), .failure(.fail)]
        let b: [Result<String, Err>] = [.success("x")]
        let result = seqRightArrayResult(a, b)
        #expect(result == [.success("x"), .failure(.fail)])
    }

    @Test func arrayTResultSeqLeft() {
        let a: [Result<Int, Err>] = [.success(1), .failure(.fail)]
        let b: [Result<String, Err>] = [.success("x")]
        let result = seqLeftArrayResult(a, b)
        #expect(result == [.success(1), .failure(.fail)])
    }

    // MARK: - ArrayTResult: Monad

    @Test func arrayTResultFlatMapTAllSuccess() {
        let arr: [Result<Int, Err>] = [.success(1), .success(2)]
        let result = arr.flatMapT { n in [.success(n), .success(n * 10)] }
        #expect(result == [.success(1), .success(10), .success(2), .success(20)])
    }

    @Test func arrayTResultFlatMapTFailurePropagates() {
        let arr: [Result<Int, Err>] = [.success(1), .failure(.fail), .success(3)]
        let result = arr.flatMapT { n in [Result<String, Err>.success("\(n)")] }
        #expect(result == [.success("1"), .failure(.fail), .success("3")])
    }

    @Test func arrayTResultFlatMapTEmpty() {
        let arr: [Result<Int, Err>] = []
        let result = arr.flatMapT { n in [Result<String, Err>.success("\(n)")] }
        #expect(result == [])
    }

    @Test func arrayTResultBindTStatic() {
        let arr: [Result<Int, Err>] = [.success(1), .success(2)]
        let result = [Result<Int, Err>].bindT { (n: Int) in [Result<Int, Err>.success(n * 2)] }(arr)
        #expect(result == [.success(2), .success(4)])
    }

    // MARK: - OptionalTArray: Functor

    @Test func optionalTArrayMapTSome() {
        let opt: [Int]? = [1, 2, 3]
        let result = opt.mapT { $0 * 2 }
        #expect(result == [2, 4, 6])
    }

    @Test func optionalTArrayMapTNone() {
        let opt: [Int]? = nil
        let result = opt.mapT { $0 * 2 }
        #expect(result == nil)
    }

    @Test func optionalTArrayFmapTStatic() {
        let opt: [Int]? = [1, 2, 3]
        let result = [Int]?.fmapT { (n: Int) in n * 2 }(opt)
        #expect(result == [2, 4, 6])
    }

    // MARK: - OptionalTArray: Applicative

    @Test func optionalTArrayApply() {
        let fns: [@Sendable (Int) -> Int]? = [{ $0 + 1 }, { $0 + 2 }]
        let values: [Int]? = [10, 20]
        let result = applyOptionalArray(fns, values)
        #expect(result == [11, 21, 12, 22])
    }

    @Test func optionalTArrayApplyNilFns() {
        let fns: [@Sendable (Int) -> Int]? = nil
        let values: [Int]? = [10, 20]
        let result = applyOptionalArray(fns, values)
        #expect(result == nil)
    }

    @Test func optionalTArrayLiftA2BothPresent() {
        let a: [Int]? = [1, 2]
        let b: [Int]? = [10, 20]
        let result = liftA2OptionalArray(+)(a, b)
        #expect(result == [11, 21, 12, 22])
    }

    @Test func optionalTArrayLiftA2LeftNil() {
        let a: [Int]? = nil
        let b: [Int]? = [10, 20]
        let result = liftA2OptionalArray(+)(a, b)
        #expect(result == nil)
    }

    @Test func optionalTArraySeqRight() {
        let a: [Int]? = [1, 2]
        let b: [String]? = ["x", "y"]
        let result = seqRightOptionalArray(a, b)
        #expect(result == ["x", "y"])
    }

    @Test func optionalTArraySeqLeft() {
        let a: [Int]? = [1, 2]
        let b: [String]? = ["x", "y"]
        let result = seqLeftOptionalArray(a, b)
        #expect(result == [1, 2])
    }

    // MARK: - OptionalTArray: Monad

    @Test func optionalTArrayFlatMapTSomeAllSucceed() {
        let opt: [Int]? = [1, 2, 3]
        let result = opt.flatMapT { n in [n, n * 10] as [Int]? }
        #expect(result == [1, 10, 2, 20, 3, 30])
    }

    @Test func optionalTArrayFlatMapTSomeOneNil() {
        let opt: [Int]? = [1, 2, 3]
        let result = opt.flatMapT { n -> [Int]? in
            n == 2 ? nil : [n, n * 10]
        }
        #expect(result == nil)
    }

    @Test func optionalTArrayFlatMapTNone() {
        let opt: [Int]? = nil
        let result = opt.flatMapT { n in [n * 2] as [Int]? }
        #expect(result == nil)
    }

    @Test func optionalTArrayBindTStatic() {
        let opt: [Int]? = [1, 2]
        let result = [Int]?.bindT { (n: Int) in [n, n + 100] as [Int]? }(opt)
        #expect(result == [1, 101, 2, 102])
    }

    // MARK: - OptionalTResult: Functor

    @Test func optionalTResultMapTSomeSuccess() throws {
        let opt: Result<Int, Err>? = .success(5)
        let result = opt.mapT { $0 * 2 }
        try #require(result != nil)
        #expect(try result?.get() == 10)
    }

    @Test func optionalTResultMapTSomeFailure() {
        let opt: Result<Int, Err>? = .failure(.fail)
        let result = opt.mapT { $0 * 2 }
        #expect(result == .some(.failure(.fail)))
    }

    @Test func optionalTResultMapTNone() {
        let opt: Result<Int, Err>? = nil
        let result = opt.mapT { $0 * 2 }
        #expect(result == nil)
    }

    @Test func optionalTResultFmapTStatic() throws {
        let opt: Result<Int, Err>? = .success(3)
        let result = Result<Int, Err>?.fmapT { (n: Int) in n * 2 }(opt)
        #expect(try result?.get() == 6)
    }

    // MARK: - OptionalTResult: Applicative

    @Test func optionalTResultApply() throws {
        let fns: Result<@Sendable (Int) -> Int, Err>? = .success { $0 + 1 }
        let values: Result<Int, Err>? = .success(10)
        let result = applyOptionalResult(fns, values)
        #expect(try result?.get() == 11)
    }

    @Test func optionalTResultLiftA2BothSuccess() throws {
        let a: Result<Int, Err>? = .success(3)
        let b: Result<Int, Err>? = .success(4)
        let result = liftA2OptionalResult(+)(a, b)
        #expect(try result?.get() == 7)
    }

    @Test func optionalTResultLiftA2LeftNil() {
        let a: Result<Int, Err>? = nil
        let b: Result<Int, Err>? = .success(4)
        let result = liftA2OptionalResult(+)(a, b)
        #expect(result == nil)
    }

    @Test func optionalTResultLiftA2LeftFailure() {
        let a: Result<Int, Err>? = .failure(.fail)
        let b: Result<Int, Err>? = .success(4)
        let result = liftA2OptionalResult(+)(a, b)
        #expect(result == .some(.failure(.fail)))
    }

    @Test func optionalTResultSeqRight() throws {
        let a: Result<Int, Err>? = .success(1)
        let b: Result<String, Err>? = .success("x")
        let result = seqRightOptionalResult(a, b)
        #expect(try result?.get() == "x")
    }

    @Test func optionalTResultSeqLeft() throws {
        let a: Result<Int, Err>? = .success(1)
        let b: Result<String, Err>? = .success("x")
        let result = seqLeftOptionalResult(a, b)
        #expect(try result?.get() == 1)
    }

    // MARK: - OptionalTResult: Monad

    @Test func optionalTResultFlatMapTSomeSuccess() throws {
        let opt: Result<Int, Err>? = .success(5)
        let result = opt.flatMapT { n in Result<String, Err>.success("\(n)") }
        #expect(try result?.get() == "5")
    }

    @Test func optionalTResultFlatMapTSomeFailure() {
        let opt: Result<Int, Err>? = .failure(.fail)
        let result = opt.flatMapT { n in Result<String, Err>.success("\(n)") }
        #expect(result == .some(.failure(.fail)))
    }

    @Test func optionalTResultFlatMapTNone() {
        let opt: Result<Int, Err>? = nil
        let result = opt.flatMapT { n in Result<String, Err>.success("\(n)") }
        #expect(result == nil)
    }

    @Test func optionalTResultFlatMapTFnReturnsNil() {
        let opt: Result<Int, Err>? = .success(5)
        let result = opt.flatMapT { _ -> Result<String, Err>? in nil }
        #expect(result == nil)
    }

    @Test func optionalTResultBindTStatic() throws {
        let opt: Result<Int, Err>? = .success(5)
        let result = Result<Int, Err>?.bindT { (n: Int) -> Result<Int, Err>? in .success(n * 2) }(opt)
        #expect(try result?.get() == 10)
    }
}

// swiftlint:enable discouraged_optional_collection
