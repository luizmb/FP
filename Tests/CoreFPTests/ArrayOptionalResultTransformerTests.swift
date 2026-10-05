// SPDX-License-Identifier: Apache-2.0
import CoreFP

// swiftlint:disable discouraged_optional_collection
import Testing

@Suite struct ArrayOptionalResultTransformerTests {
    private enum Err: Error, Equatable { case fail }

    // MARK: - ArrayTOptional: Functor

    @Test func arrayTOptionalMapAllPresent() {
        let arr: [Int?] = [1, 2, 3]
        let result = arr.arrayT.map { $0 * 2 }.rawValue
        #expect(result == [2, 4, 6])
    }

    @Test func arrayTOptionalMapWithNils() {
        let arr: [Int?] = [1, nil, 3]
        let result = arr.arrayT.map { $0 * 2 }.rawValue
        #expect(result == [2, nil, 6])
    }

    @Test func arrayTOptionalFmapStatic() {
        let arr: [Int?] = [1, nil, 3]
        let result = ArrayTOptional<Int>.fmap { n in n * 2 }(arr.arrayT).rawValue
        #expect(result == [2, nil, 6])
    }

    // MARK: - ArrayTOptional: Applicative

    @Test func arrayTOptionalApply() {
        let fns: [(@Sendable (Int) -> Int)?] = [{ $0 + 1 }, nil]
        let values: [Int?] = [10, 20]
        let result = ArrayTOptional.apply(fns.arrayT, values.arrayT).rawValue
        // MaybeT []: a nil function short-circuits to a single nil (<*> = ap)
        #expect(result == [11, 21, nil])
    }

    @Test func arrayTOptionalLiftA2CartesianProduct() {
        let a: [Int?] = [1, 2]
        let b: [Int?] = [10, 20]
        let result = ArrayTOptional<Int>.liftA2(+)(a.arrayT, b.arrayT).rawValue
        #expect(result == [11, 21, 12, 22])
    }

    @Test func arrayTOptionalLiftA2WithNils() {
        let a: [Int?] = [1, nil]
        let b: [Int?] = [10]
        let result = ArrayTOptional<Int>.liftA2(+)(a.arrayT, b.arrayT).rawValue
        #expect(result == [11, nil])
    }

    @Test func arrayTOptionalSeqRight() {
        let a: [Int?] = [1, nil]
        let b: [String?] = ["x", nil]
        let result = a.arrayT.seqRight(b.arrayT).rawValue
        // MaybeT []: nil on the left short-circuits to a single nil
        #expect(result == ["x", nil, nil])
    }

    @Test func arrayTOptionalSeqLeft() {
        let a: [Int?] = [1, nil]
        let b: [String?] = ["x"]
        let result = a.arrayT.seqLeft(b.arrayT).rawValue
        #expect(result == [1, nil])
    }

    // MARK: - ArrayTOptional: Monad

    @Test func arrayTOptionalFlatMapAllPresent() {
        let arr: [Int?] = [1, 2, 3]
        let result = arr.arrayT.flatMap { n in ArrayTOptional([n, n * 10]) }.rawValue
        #expect(result == [1, 10, 2, 20, 3, 30])
    }

    @Test func arrayTOptionalFlatMapNilPropagates() {
        let arr: [Int?] = [1, nil, 3]
        let result = arr.arrayT.flatMap { n in ArrayTOptional([n * 2]) }.rawValue
        #expect(result == [2, nil, 6])
    }

    @Test func arrayTOptionalFlatMapEmpty() {
        let arr: [Int?] = []
        let result = arr.arrayT.flatMap { n in ArrayTOptional([n * 2]) }.rawValue
        #expect(result == [])
    }

    @Test func arrayTOptionalBindStatic() {
        let arr: [Int?] = [1, 2]
        let result = ArrayTOptional<Int>.bind { n in ArrayTOptional([n, n + 100]) }(arr.arrayT).rawValue
        #expect(result == [1, 101, 2, 102])
    }

    // MARK: - ArrayTResult: Functor

    @Test func arrayTResultMapAllSuccess() throws {
        let arr: [Result<Int, Err>] = [.success(1), .success(2), .success(3)]
        let result = arr.arrayT.map { $0 * 2 }.rawValue
        #expect(try result.map { try $0.get() } == [2, 4, 6])
    }

    @Test func arrayTResultMapWithFailure() {
        let arr: [Result<Int, Err>] = [.success(1), .failure(.fail), .success(3)]
        let result = arr.arrayT.map { $0 * 2 }.rawValue
        #expect(result == [.success(2), .failure(.fail), .success(6)])
    }

    @Test func arrayTResultFmapStatic() {
        let arr: [Result<Int, Err>] = [.success(1), .failure(.fail)]
        let result = ArrayTResult<Err, Int>.fmap { n in n * 2 }(arr.arrayT).rawValue
        #expect(result == [.success(2), .failure(.fail)])
    }

    // MARK: - ArrayTResult: Applicative

    @Test func arrayTResultApply() {
        let fns: [Result<@Sendable (Int) -> Int, Err>] = [.success { $0 + 1 }, .failure(.fail)]
        let values: [Result<Int, Err>] = [.success(10)]
        let result = ArrayTResult.apply(fns.arrayT, values.arrayT).rawValue
        #expect(result == [.success(11), .failure(.fail)])
    }

    @Test func arrayTResultLiftA2CartesianProduct() {
        let a: [Result<Int, Err>] = [.success(1), .success(2)]
        let b: [Result<Int, Err>] = [.success(10), .success(20)]
        let result = ArrayTResult<Err, Int>.liftA2(+)(a.arrayT, b.arrayT).rawValue
        #expect(result == [.success(11), .success(21), .success(12), .success(22)])
    }

    @Test func arrayTResultLiftA2WithFailure() {
        let a: [Result<Int, Err>] = [.success(1), .failure(.fail)]
        let b: [Result<Int, Err>] = [.success(10)]
        let result = ArrayTResult<Err, Int>.liftA2(+)(a.arrayT, b.arrayT).rawValue
        #expect(result == [.success(11), .failure(.fail)])
    }

    @Test func arrayTResultSeqRight() {
        let a: [Result<Int, Err>] = [.success(1), .failure(.fail)]
        let b: [Result<String, Err>] = [.success("x")]
        let result = a.arrayT.seqRight(b.arrayT).rawValue
        #expect(result == [.success("x"), .failure(.fail)])
    }

    @Test func arrayTResultSeqLeft() {
        let a: [Result<Int, Err>] = [.success(1), .failure(.fail)]
        let b: [Result<String, Err>] = [.success("x")]
        let result = a.arrayT.seqLeft(b.arrayT).rawValue
        #expect(result == [.success(1), .failure(.fail)])
    }

    // MARK: - ArrayTResult: Monad

    @Test func arrayTResultFlatMapAllSuccess() {
        let arr: [Result<Int, Err>] = [.success(1), .success(2)]
        let result = arr.arrayT.flatMap { n in ArrayTResult([.success(n), .success(n * 10)]) }.rawValue
        #expect(result == [.success(1), .success(10), .success(2), .success(20)])
    }

    @Test func arrayTResultFlatMapFailurePropagates() {
        let arr: [Result<Int, Err>] = [.success(1), .failure(.fail), .success(3)]
        let result = arr.arrayT.flatMap { n in ArrayTResult<Err, String>([.success("\(n)")]) }.rawValue
        #expect(result == [.success("1"), .failure(.fail), .success("3")])
    }

    @Test func arrayTResultFlatMapEmpty() {
        let arr: [Result<Int, Err>] = []
        let result = arr.arrayT.flatMap { n in ArrayTResult<Err, String>([.success("\(n)")]) }.rawValue
        #expect(result == [])
    }

    @Test func arrayTResultBindStatic() {
        let arr: [Result<Int, Err>] = [.success(1), .success(2)]
        let result = ArrayTResult<Err, Int>.bind { n in ArrayTResult<Err, Int>([.success(n * 2)]) }(arr.arrayT).rawValue
        #expect(result == [.success(2), .success(4)])
    }

    // MARK: - OptionalTArray: Functor

    @Test func optionalTArrayMapSome() {
        let opt: [Int]? = [1, 2, 3]
        let result = opt.optionalT.map { $0 * 2 }.rawValue
        #expect(result == [2, 4, 6])
    }

    @Test func optionalTArrayMapNone() {
        let opt: [Int]? = nil
        let result = opt.optionalT.map { $0 * 2 }.rawValue
        #expect(result == nil)
    }

    @Test func optionalTArrayFmapStatic() {
        let opt: [Int]? = [1, 2, 3]
        let result = OptionalTArray<Int>.fmap { n in n * 2 }(opt.optionalT).rawValue
        #expect(result == [2, 4, 6])
    }

    // MARK: - OptionalTArray: Applicative

    @Test func optionalTArrayApply() {
        let fns: [@Sendable (Int) -> Int]? = [{ $0 + 1 }, { $0 + 2 }]
        let values: [Int]? = [10, 20]
        let result = OptionalTArray.apply(fns.optionalT, values.optionalT).rawValue
        #expect(result == [11, 21, 12, 22])
    }

    @Test func optionalTArrayApplyNilFns() {
        let fns: [@Sendable (Int) -> Int]? = nil
        let values: [Int]? = [10, 20]
        let result = OptionalTArray.apply(fns.optionalT, values.optionalT).rawValue
        #expect(result == nil)
    }

    @Test func optionalTArrayLiftA2BothPresent() {
        let a: [Int]? = [1, 2]
        let b: [Int]? = [10, 20]
        let result = OptionalTArray<Int>.liftA2(+)(a.optionalT, b.optionalT).rawValue
        #expect(result == [11, 21, 12, 22])
    }

    @Test func optionalTArrayLiftA2LeftNil() {
        let a: [Int]? = nil
        let b: [Int]? = [10, 20]
        let result = OptionalTArray<Int>.liftA2(+)(a.optionalT, b.optionalT).rawValue
        #expect(result == nil)
    }

    @Test func optionalTArraySeqRight() {
        let a: [Int]? = [1, 2]
        let b: [String]? = ["x", "y"]
        let result = a.optionalT.seqRight(b.optionalT).rawValue
        #expect(result == ["x", "y"])
    }

    @Test func optionalTArraySeqLeft() {
        let a: [Int]? = [1, 2]
        let b: [String]? = ["x", "y"]
        let result = a.optionalT.seqLeft(b.optionalT).rawValue
        #expect(result == [1, 2])
    }

    // MARK: - OptionalTArray: Monad

    @Test func optionalTArrayFlatMapSomeAllSucceed() {
        let opt: [Int]? = [1, 2, 3]
        let result = opt.optionalT.flatMap { n in OptionalTArray([n, n * 10]) }.rawValue
        #expect(result == [1, 10, 2, 20, 3, 30])
    }

    @Test func optionalTArrayFlatMapSomeOneNil() {
        let opt: [Int]? = [1, 2, 3]
        let result = opt.optionalT.flatMap { n in
            OptionalTArray(n == 2 ? nil : [n, n * 10])
        }.rawValue
        #expect(result == nil)
    }

    @Test func optionalTArrayFlatMapNone() {
        let opt: [Int]? = nil
        let result = opt.optionalT.flatMap { n in OptionalTArray([n * 2]) }.rawValue
        #expect(result == nil)
    }

    @Test func optionalTArrayBindStatic() {
        let opt: [Int]? = [1, 2]
        let result = OptionalTArray<Int>.bind { n in OptionalTArray([n, n + 100]) }(opt.optionalT).rawValue
        #expect(result == [1, 101, 2, 102])
    }

    // MARK: - OptionalTResult: Functor

    @Test func optionalTResultMapSomeSuccess() throws {
        let opt: Result<Int, Err>? = .success(5)
        let result = opt.optionalT.map { $0 * 2 }.rawValue
        try #require(result != nil)
        #expect(try result?.get() == 10)
    }

    @Test func optionalTResultMapSomeFailure() {
        let opt: Result<Int, Err>? = .failure(.fail)
        let result = opt.optionalT.map { $0 * 2 }.rawValue
        #expect(result == .some(.failure(.fail)))
    }

    @Test func optionalTResultMapNone() {
        let opt: Result<Int, Err>? = nil
        let result = opt.optionalT.map { $0 * 2 }.rawValue
        #expect(result == nil)
    }

    @Test func optionalTResultFmapStatic() throws {
        let opt: Result<Int, Err>? = .success(3)
        let result = OptionalTResult<Err, Int>.fmap { n in n * 2 }(opt.optionalT).rawValue
        #expect(try result?.get() == 6)
    }

    // MARK: - OptionalTResult: Applicative

    @Test func optionalTResultApply() throws {
        let fns: Result<@Sendable (Int) -> Int, Err>? = .success { $0 + 1 }
        let values: Result<Int, Err>? = .success(10)
        let result = OptionalTResult.apply(fns.optionalT, values.optionalT).rawValue
        #expect(try result?.get() == 11)
    }

    @Test func optionalTResultLiftA2BothSuccess() throws {
        let a: Result<Int, Err>? = .success(3)
        let b: Result<Int, Err>? = .success(4)
        let result = OptionalTResult<Err, Int>.liftA2(+)(a.optionalT, b.optionalT).rawValue
        #expect(try result?.get() == 7)
    }

    @Test func optionalTResultLiftA2LeftNil() {
        let a: Result<Int, Err>? = nil
        let b: Result<Int, Err>? = .success(4)
        let result = OptionalTResult<Err, Int>.liftA2(+)(a.optionalT, b.optionalT).rawValue
        #expect(result == nil)
    }

    @Test func optionalTResultLiftA2LeftFailure() {
        let a: Result<Int, Err>? = .failure(.fail)
        let b: Result<Int, Err>? = .success(4)
        let result = OptionalTResult<Err, Int>.liftA2(+)(a.optionalT, b.optionalT).rawValue
        #expect(result == .some(.failure(.fail)))
    }

    @Test func optionalTResultSeqRight() throws {
        let a: Result<Int, Err>? = .success(1)
        let b: Result<String, Err>? = .success("x")
        let result = a.optionalT.seqRight(b.optionalT).rawValue
        #expect(try result?.get() == "x")
    }

    @Test func optionalTResultSeqLeft() throws {
        let a: Result<Int, Err>? = .success(1)
        let b: Result<String, Err>? = .success("x")
        let result = a.optionalT.seqLeft(b.optionalT).rawValue
        #expect(try result?.get() == 1)
    }

    // MARK: - OptionalTResult: Monad

    @Test func optionalTResultFlatMapSomeSuccess() throws {
        let opt: Result<Int, Err>? = .success(5)
        let result = opt.optionalT.flatMap { n in OptionalTResult<Err, String>(.success("\(n)")) }.rawValue
        #expect(try result?.get() == "5")
    }

    @Test func optionalTResultFlatMapSomeFailure() {
        let opt: Result<Int, Err>? = .failure(.fail)
        let result = opt.optionalT.flatMap { n in OptionalTResult<Err, String>(.success("\(n)")) }.rawValue
        #expect(result == .some(.failure(.fail)))
    }

    @Test func optionalTResultFlatMapNone() {
        let opt: Result<Int, Err>? = nil
        let result = opt.optionalT.flatMap { n in OptionalTResult<Err, String>(.success("\(n)")) }.rawValue
        #expect(result == nil)
    }

    @Test func optionalTResultFlatMapFnReturnsNil() {
        let opt: Result<Int, Err>? = .success(5)
        let result = opt.optionalT.flatMap(const(OptionalTResult<Err, String>(nil))).rawValue
        #expect(result == nil)
    }

    @Test func optionalTResultBindStatic() throws {
        let opt: Result<Int, Err>? = .success(5)
        let result = OptionalTResult<Err, Int>.bind { n in OptionalTResult<Err, Int>(.success(n * 2)) }(opt.optionalT).rawValue
        #expect(try result?.get() == 10)
    }
}

// swiftlint:enable discouraged_optional_collection
