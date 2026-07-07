// SPDX-License-Identifier: Apache-2.0
import CoreFP

// swiftlint:disable discouraged_optional_collection
import Testing

@Suite struct KleisliTTests {
    private enum TestError: Error, Equatable {
        case broken
    }

    // MARK: - ArrayTOptional

    @Test func arrayTOptionalSuccessPath() {
        let branch: @Sendable (Int) -> [Int?] = { n in [n, n + 1] }
        let tenfold: @Sendable (Int) -> [Int?] = { n in [n * 10] }
        let composed = kleisliT(branch, tenfold)
        #expect(composed(1) == [10, 20])
    }

    @Test func arrayTOptionalNilPath() {
        let stop: @Sendable (Int) -> [Int?] = const([nil])
        let tenfold: @Sendable (Int) -> [Int?] = { n in [n * 10] }
        let composed = kleisliT(stop, tenfold)
        #expect(composed(1) == [nil])
    }

    // MARK: - ArrayTResult

    @Test func arrayTResultSuccessPath() {
        let branch: @Sendable (Int) -> [Result<Int, TestError>] = { n in [.success(n), .success(n + 1)] }
        let tenfold: @Sendable (Int) -> [Result<Int, TestError>] = { n in [.success(n * 10)] }
        let composed = kleisliT(branch, tenfold)
        #expect(composed(1) == [.success(10), .success(20)])
    }

    @Test func arrayTResultFailurePath() {
        let fail: @Sendable (Int) -> [Result<Int, TestError>] = const([.failure(.broken)])
        let tenfold: @Sendable (Int) -> [Result<Int, TestError>] = { n in [.success(n * 10)] }
        let composed = kleisliT(fail, tenfold)
        #expect(composed(1) == [.failure(.broken)])
    }

    // MARK: - OptionalTArray

    @Test func optionalTArraySuccessPath() {
        let branch: @Sendable (Int) -> [Int]? = { n in [n, n + 1] }
        let tenfold: @Sendable (Int) -> [Int]? = { n in [n * 10] }
        let composed = kleisliT(branch, tenfold)
        #expect(composed(1) == [10, 20])
    }

    @Test func optionalTArrayNilPath() {
        let stop: @Sendable (Int) -> [Int]? = const(nil)
        let tenfold: @Sendable (Int) -> [Int]? = { n in [n * 10] }
        let composed = kleisliT(stop, tenfold)
        #expect(composed(1) == nil)
    }

    // MARK: - OptionalTResult

    @Test func optionalTResultSuccessPath() {
        let increment: @Sendable (Int) -> Result<Int, TestError>? = { n in .success(n + 1) }
        let tenfold: @Sendable (Int) -> Result<Int, TestError>? = { n in .success(n * 10) }
        let composed = kleisliT(increment, tenfold)
        #expect(composed(1) == .success(20))
    }

    @Test func optionalTResultFailurePath() {
        let fail: @Sendable (Int) -> Result<Int, TestError>? = const(.failure(.broken))
        let tenfold: @Sendable (Int) -> Result<Int, TestError>? = { n in .success(n * 10) }
        let composed = kleisliT(fail, tenfold)
        #expect(composed(1) == .failure(.broken))
    }
}

// swiftlint:enable discouraged_optional_collection
