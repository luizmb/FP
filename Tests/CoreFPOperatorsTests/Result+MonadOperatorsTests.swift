// SPDX-License-Identifier: Apache-2.0
@testable import CoreFP
@testable import CoreFPOperators
import Foundation
import Testing

@Suite struct ResultMonadTests {
    @Test func bind() {
        let value: Result<Int, NSError> = .success(5)
        let result = value >>- { x in .success(x * 2) }
        #expect((try? result.get()) == 10)

        let error: Result<Int, NSError> = .failure(NSError(domain: "test", code: 1))
        let errorResult = error >>- { x in .success(x * 2) }
        #expect(throws: (any Error).self) { try errorResult.get() }
    }

    @Test func flippedBind() {
        let double: @Sendable (Int) -> Result<Int, NSError> = { .success($0 * 2) }
        let value: Result<Int, NSError> = .success(5)
        let result = double -<< value
        #expect((try? result.get()) == 10)
    }

    @Test func kleisliComposition() {
        let safe: @Sendable (Int) -> Result<Int, NSError> = { $0 > 0 ? .success($0) : .failure(NSError(domain: "test", code: 1)) }
        let double: @Sendable (Int) -> Result<Int, NSError> = { .success($0 * 2) }

        let composed = safe >=> double
        #expect((try? composed(5).get()) == 10)
        #expect(throws: (any Error).self) { try composed(-1).get() }
    }

    @Test func flippedFmap() {
        let value: Result<Int, NSError> = .success(5)
        let result = value <&> { $0 * 2 }
        #expect((try? result.get()) == 10)
    }

    @Test func alternative() {
        let success: Result<Int, NSError> = .success(5)
        let failure: Result<Int, NSError> = .failure(NSError(domain: "test", code: 1))
        let alternative: Result<Int, NSError> = .success(10)

        #expect((try? (success <|> alternative).get()) == 5)
        #expect((try? (failure <|> alternative).get()) == 10)
    }

    @Test func void() {
        let success: Result<Int, NSError> = .success(5)
        let voided = success.void()
        #expect(throws: Never.self) { try voided.get() }
    }

    // MARK: - join / void free functions

    private enum JoinTestError: Error { case fail }

    @Test func joinFreeFunction() {
        let nested: Result<Result<Int, JoinTestError>, JoinTestError> = .success(.success(42))
        #expect((try? CoreFP.join(nested).get()) == 42)
    }

    @Test func joinOuterFailure() {
        let nested: Result<Result<Int, JoinTestError>, JoinTestError> = .failure(.fail)
        #expect(throws: (any Error).self) { try CoreFP.join(nested).get() }
    }

    @Test func joinInnerFailure() {
        let nested: Result<Result<Int, JoinTestError>, JoinTestError> = .success(.failure(.fail))
        #expect(throws: (any Error).self) { try CoreFP.join(nested).get() }
    }

    @Test func voidFreeFunction() {
        let success: Result<Int, JoinTestError> = .success(5)
        #expect(throws: Never.self) { try CoreFP.void(success).get() }
    }

    @Test func voidFreeFunctionFailure() {
        let failure: Result<Int, JoinTestError> = .failure(.fail)
        #expect(throws: (any Error).self) { try CoreFP.void(failure).get() }
    }
}
