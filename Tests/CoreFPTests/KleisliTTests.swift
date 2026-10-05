// SPDX-License-Identifier: Apache-2.0
import CoreFP

import Testing

@Suite struct KleisliTTests {
    private enum TestError: Error, Equatable {
        case broken
    }

    // MARK: - ArrayTOptional

    @Test func arrayTOptionalSuccessPath() {
        let branch: @Sendable (Int) -> ArrayTOptional<Int> = { n in ArrayTOptional([n, n + 1]) }
        let tenfold: @Sendable (Int) -> ArrayTOptional<Int> = { n in ArrayTOptional([n * 10]) }
        let composed = ArrayTOptional<Int>.kleisli(branch, tenfold)
        #expect(composed(1).rawValue == [10, 20])
    }

    @Test func arrayTOptionalNilPath() {
        let stop: @Sendable (Int) -> ArrayTOptional<Int> = const(ArrayTOptional([nil]))
        let tenfold: @Sendable (Int) -> ArrayTOptional<Int> = { n in ArrayTOptional([n * 10]) }
        let composed = ArrayTOptional<Int>.kleisli(stop, tenfold)
        #expect(composed(1).rawValue == [nil])
    }

    // MARK: - ArrayTResult

    @Test func arrayTResultSuccessPath() {
        let branch: @Sendable (Int) -> ArrayTResult<TestError, Int> = { n in ArrayTResult([.success(n), .success(n + 1)]) }
        let tenfold: @Sendable (Int) -> ArrayTResult<TestError, Int> = { n in ArrayTResult([.success(n * 10)]) }
        let composed = ArrayTResult<TestError, Int>.kleisli(branch, tenfold)
        #expect(composed(1).rawValue == [.success(10), .success(20)])
    }

    @Test func arrayTResultFailurePath() {
        let fail: @Sendable (Int) -> ArrayTResult<TestError, Int> = const(ArrayTResult([.failure(.broken)]))
        let tenfold: @Sendable (Int) -> ArrayTResult<TestError, Int> = { n in ArrayTResult([.success(n * 10)]) }
        let composed = ArrayTResult<TestError, Int>.kleisli(fail, tenfold)
        #expect(composed(1).rawValue == [.failure(.broken)])
    }

    // MARK: - OptionalTArray

    @Test func optionalTArraySuccessPath() {
        let branch: @Sendable (Int) -> OptionalTArray<Int> = { n in OptionalTArray([n, n + 1]) }
        let tenfold: @Sendable (Int) -> OptionalTArray<Int> = { n in OptionalTArray([n * 10]) }
        let composed = OptionalTArray<Int>.kleisli(branch, tenfold)
        #expect(composed(1).rawValue == [10, 20])
    }

    @Test func optionalTArrayNilPath() {
        let stop: @Sendable (Int) -> OptionalTArray<Int> = const(OptionalTArray(nil))
        let tenfold: @Sendable (Int) -> OptionalTArray<Int> = { n in OptionalTArray([n * 10]) }
        let composed = OptionalTArray<Int>.kleisli(stop, tenfold)
        #expect(composed(1).rawValue == nil)
    }

    // MARK: - OptionalTResult

    @Test func optionalTResultSuccessPath() {
        let increment: @Sendable (Int) -> OptionalTResult<TestError, Int> = { n in OptionalTResult(.success(n + 1)) }
        let tenfold: @Sendable (Int) -> OptionalTResult<TestError, Int> = { n in OptionalTResult(.success(n * 10)) }
        let composed = OptionalTResult<TestError, Int>.kleisli(increment, tenfold)
        #expect(composed(1).rawValue == .success(20))
    }

    @Test func optionalTResultFailurePath() {
        let fail: @Sendable (Int) -> OptionalTResult<TestError, Int> = const(OptionalTResult(.failure(.broken)))
        let tenfold: @Sendable (Int) -> OptionalTResult<TestError, Int> = { n in OptionalTResult(.success(n * 10)) }
        let composed = OptionalTResult<TestError, Int>.kleisli(fail, tenfold)
        #expect(composed(1).rawValue == .failure(.broken))
    }
}
