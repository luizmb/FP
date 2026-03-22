import Testing
@testable import CoreFP

@Suite struct TraversableTests {

    private enum TestError: Error, Equatable {
        case fail
    }

    // MARK: - Optional as Traversable

    // traverse :: (a -> [b]) -> a? -> [b?]

    @Test func optionalTraverseArrayNone() {
        let result = (nil as Int?).traverse { [$0, $0 * 2] }
        #expect(result == [nil])
    }

    @Test func optionalTraverseArraySome() {
        let result = Optional(3).traverse { [$0, $0 * 2] }
        #expect(result == [3, 6])
    }

    @Test func optionalSequenceArray() {
        #expect((nil as [Int]?).sequence() == [nil])
        #expect(Optional([1, 2, 3]).sequence() == [1, 2, 3])
    }

    // traverse :: (a -> b?) -> a? -> b??

    @Test func optionalTraverseOptionalNone() {
        // Nothing → Just Nothing
        let result = (nil as Int?).traverse { Optional($0 * 2) }
        #expect(result == .some(.none))
    }

    @Test func optionalTraverseOptionalSomeSuccess() {
        // Just a, f succeeds → Just (Just b)
        let result = Optional(3).traverse { Optional($0 * 2) }
        #expect(result == .some(.some(6)))
    }

    @Test func optionalTraverseOptionalSomeFailure() {
        // Just a, f returns nil → Nothing
        let result = Optional(3).traverse { _ in nil as Int? }
        #expect(result == .none)
    }

    @Test func optionalSequenceOptional() {
        // Nothing → Just Nothing
        let noneInput: Int?? = .none
        #expect(noneInput.sequence() == .some(.none))

        // Just Nothing → Nothing
        let someNone: Int?? = .some(.none)
        #expect(someNone.sequence() == .none)

        // Just (Just a) → Just (Just a)
        let someSome: Int?? = .some(.some(3))
        #expect(someSome.sequence() == .some(.some(3)))
    }

    // traverse :: (a -> Result<b,e>) -> a? -> Result<b?,e>

    @Test func optionalTraverseResultNone() {
        // Nothing → Right Nothing
        let result = (nil as Int?).traverse { _ in Result<Int, TestError>.success(0) }
        #expect(result == .success(.none))
    }

    @Test func optionalTraverseResultSomeSuccess() {
        // Just a, f succeeds → Right (Just b)
        let result = Optional(3).traverse { Result<Int, TestError>.success($0 * 2) }
        #expect(result == .success(.some(6)))
    }

    @Test func optionalTraverseResultSomeFailure() {
        // Just a, f fails → Left e
        let result = Optional(3).traverse { _ in Result<Int, TestError>.failure(.fail) }
        #expect(result == .failure(.fail))
    }

    @Test func optionalSequenceResult() {
        let noneInput: Result<Int, TestError>? = .none
        #expect(noneInput.sequence() == .success(.none))

        let someSuccess: Result<Int, TestError>? = .some(.success(3))
        #expect(someSuccess.sequence() == .success(.some(3)))

        let someFailure: Result<Int, TestError>? = .some(.failure(.fail))
        #expect(someFailure.sequence() == .failure(.fail))
    }

    // MARK: - Array as Traversable

    // traverse :: (a -> b?) -> [a] -> [b]?

    @Test func arrayTraverseOptionalEmpty() {
        // [] → Just []
        let result = [Int]().traverse { Optional($0 * 2) }
        #expect(result == .some([]))
    }

    @Test func arrayTraverseOptionalAllSucceed() {
        let result = [1, 2, 3].traverse { Optional($0 * 2) }
        #expect(result == .some([2, 4, 6]))
    }

    @Test func arrayTraverseOptionalOneNil() {
        // Any nil → Nothing
        let result = [1, 2, 3].traverse { $0 == 2 ? nil : Optional($0 * 2) }
        #expect(result == .none)
    }

    @Test func arraySequenceOptional() {
        #expect([Int?]().sequence() == .some([]))
        #expect([Optional(1), Optional(2), Optional(3)].sequence() == .some([1, 2, 3]))
        #expect([Optional(1), nil, Optional(3)].sequence() == .none)
    }

    // traverse :: (a -> Result<b,e>) -> [a] -> Result<[b],e>

    @Test func arrayTraverseResultEmpty() {
        // [] → Right []
        let result = [Int]().traverse { Result<Int, TestError>.success($0 * 2) }
        #expect(result == .success([]))
    }

    @Test func arrayTraverseResultAllSucceed() {
        let result = [1, 2, 3].traverse { Result<Int, TestError>.success($0 * 2) }
        #expect(result == .success([2, 4, 6]))
    }

    @Test func arrayTraverseResultFirstFailure() {
        // Short-circuits on first failure
        let result = [1, 2, 3].traverse { $0 == 2 ? .failure(TestError.fail) : .success($0 * 2) }
        #expect(result == .failure(.fail))
    }

    @Test func arraySequenceResult() {
        let allSuccess: [Result<Int, TestError>] = [.success(1), .success(2), .success(3)]
        #expect(allSuccess.sequence() == .success([1, 2, 3]))

        let withFailure: [Result<Int, TestError>] = [.success(1), .failure(.fail), .success(3)]
        #expect(withFailure.sequence() == .failure(.fail))
    }

    // traverse :: (a -> [b]) -> [a] -> [[b]]

    @Test func arrayTraverseArrayEmpty() {
        // [] → [[]] (pure [] in list applicative)
        let result = [Int]().traverse { [$0, $0 * 10] }
        #expect(result == [[]])
    }

    @Test func arrayTraverseArrayCartesianProduct() {
        // traverse (\x -> [x, x*10]) [1,2] = [[1,2],[1,20],[10,2],[10,20]]
        let result = [1, 2].traverse { [$0, $0 * 10] }
        #expect(result == [[1, 2], [1, 20], [10, 2], [10, 20]])
    }

    @Test func arraySequenceArrayCartesianProduct() {
        // sequence [[1,2],[3,4]] = [[1,3],[1,4],[2,3],[2,4]]
        let result = [[1, 2], [3, 4]].sequence()
        #expect(result == [[1, 3], [1, 4], [2, 3], [2, 4]])
    }
}
