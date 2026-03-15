import XCTest
@testable import FP

final class TraversableTests: XCTestCase {

    private enum TestError: Error, Equatable {
        case fail
    }

    // MARK: - Optional as Traversable

    // traverse :: (a -> [b]) -> a? -> [b?]

    func testOptionalTraverseArrayNone() {
        let result = (nil as Int?).traverse { [$0, $0 * 2] }
        XCTAssertEqual(result, [nil])
    }

    func testOptionalTraverseArraySome() {
        let result = Optional(3).traverse { [$0, $0 * 2] }
        XCTAssertEqual(result, [3, 6])
    }

    func testOptionalSequenceArray() {
        XCTAssertEqual((nil as [Int]?).sequence(), [nil])
        XCTAssertEqual(Optional([1, 2, 3]).sequence(), [1, 2, 3])
    }

    // traverse :: (a -> b?) -> a? -> b??

    func testOptionalTraverseOptionalNone() {
        // Nothing → Just Nothing
        let result = (nil as Int?).traverse { Optional($0 * 2) }
        XCTAssertEqual(result, .some(.none))
    }

    func testOptionalTraverseOptionalSomeSuccess() {
        // Just a, f succeeds → Just (Just b)
        let result = Optional(3).traverse { Optional($0 * 2) }
        XCTAssertEqual(result, .some(.some(6)))
    }

    func testOptionalTraverseOptionalSomeFailure() {
        // Just a, f returns nil → Nothing
        let result = Optional(3).traverse { _ in nil as Int? }
        XCTAssertEqual(result, .none)
    }

    func testOptionalSequenceOptional() {
        // Nothing → Just Nothing
        let noneInput: Int?? = .none
        XCTAssertEqual(noneInput.sequence(), .some(.none))

        // Just Nothing → Nothing
        let someNone: Int?? = .some(.none)
        XCTAssertEqual(someNone.sequence(), .none)

        // Just (Just a) → Just (Just a)
        let someSome: Int?? = .some(.some(3))
        XCTAssertEqual(someSome.sequence(), .some(.some(3)))
    }

    // traverse :: (a -> Result<b,e>) -> a? -> Result<b?,e>

    func testOptionalTraverseResultNone() {
        // Nothing → Right Nothing
        let result = (nil as Int?).traverse { _ in Result<Int, TestError>.success(0) }
        XCTAssertEqual(result, .success(.none))
    }

    func testOptionalTraverseResultSomeSuccess() {
        // Just a, f succeeds → Right (Just b)
        let result = Optional(3).traverse { Result<Int, TestError>.success($0 * 2) }
        XCTAssertEqual(result, .success(.some(6)))
    }

    func testOptionalTraverseResultSomeFailure() {
        // Just a, f fails → Left e
        let result = Optional(3).traverse { _ in Result<Int, TestError>.failure(.fail) }
        XCTAssertEqual(result, .failure(.fail))
    }

    func testOptionalSequenceResult() {
        let noneInput: Result<Int, TestError>? = .none
        XCTAssertEqual(noneInput.sequence(), .success(.none))

        let someSuccess: Result<Int, TestError>? = .some(.success(3))
        XCTAssertEqual(someSuccess.sequence(), .success(.some(3)))

        let someFailure: Result<Int, TestError>? = .some(.failure(.fail))
        XCTAssertEqual(someFailure.sequence(), .failure(.fail))
    }

    // MARK: - Array as Traversable

    // traverse :: (a -> b?) -> [a] -> [b]?

    func testArrayTraverseOptionalEmpty() {
        // [] → Just []
        let result = [Int]().traverse { Optional($0 * 2) }
        XCTAssertEqual(result, .some([]))
    }

    func testArrayTraverseOptionalAllSucceed() {
        let result = [1, 2, 3].traverse { Optional($0 * 2) }
        XCTAssertEqual(result, .some([2, 4, 6]))
    }

    func testArrayTraverseOptionalOneNil() {
        // Any nil → Nothing
        let result = [1, 2, 3].traverse { $0 == 2 ? nil : Optional($0 * 2) }
        XCTAssertEqual(result, .none)
    }

    func testArraySequenceOptional() {
        XCTAssertEqual([Int?]().sequence(), .some([]))
        XCTAssertEqual([Optional(1), Optional(2), Optional(3)].sequence(), .some([1, 2, 3]))
        XCTAssertEqual([Optional(1), nil, Optional(3)].sequence(), .none)
    }

    // traverse :: (a -> Result<b,e>) -> [a] -> Result<[b],e>

    func testArrayTraverseResultEmpty() {
        // [] → Right []
        let result = [Int]().traverse { Result<Int, TestError>.success($0 * 2) }
        XCTAssertEqual(result, .success([]))
    }

    func testArrayTraverseResultAllSucceed() {
        let result = [1, 2, 3].traverse { Result<Int, TestError>.success($0 * 2) }
        XCTAssertEqual(result, .success([2, 4, 6]))
    }

    func testArrayTraverseResultFirstFailure() {
        // Short-circuits on first failure
        let result = [1, 2, 3].traverse { $0 == 2 ? .failure(TestError.fail) : .success($0 * 2) }
        XCTAssertEqual(result, .failure(.fail))
    }

    func testArraySequenceResult() {
        let allSuccess: [Result<Int, TestError>] = [.success(1), .success(2), .success(3)]
        XCTAssertEqual(allSuccess.sequence(), .success([1, 2, 3]))

        let withFailure: [Result<Int, TestError>] = [.success(1), .failure(.fail), .success(3)]
        XCTAssertEqual(withFailure.sequence(), .failure(.fail))
    }

    // traverse :: (a -> [b]) -> [a] -> [[b]]

    func testArrayTraverseArrayEmpty() {
        // [] → [[]] (pure [] in list applicative)
        let result = [Int]().traverse { [$0, $0 * 10] }
        XCTAssertEqual(result, [[]])
    }

    func testArrayTraverseArrayCartesianProduct() {
        // traverse (\x -> [x, x*10]) [1,2] = [[1,2],[1,20],[10,2],[10,20]]
        let result = [1, 2].traverse { [$0, $0 * 10] }
        XCTAssertEqual(result, [[1, 2], [1, 20], [10, 2], [10, 20]])
    }

    func testArraySequenceArrayCartesianProduct() {
        // sequence [[1,2],[3,4]] = [[1,3],[1,4],[2,3],[2,4]]
        let result = [[1, 2], [3, 4]].sequence()
        XCTAssertEqual(result, [[1, 3], [1, 4], [2, 3], [2, 4]])
    }
}
