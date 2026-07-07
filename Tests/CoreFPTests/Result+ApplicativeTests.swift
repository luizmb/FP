// SPDX-License-Identifier: Apache-2.0
@testable import CoreFP
import Testing

private enum TestError: Error, Equatable {
    case sample
}

@Suite struct ResultCoreApplicativeTests {
    // MARK: - pure

    @Test func pureLiftsIntoSuccess() {
        let result: Result<Int, TestError> = Result.pure(42)
        #expect(result == .success(42))
    }

    @Test func pureIsLeftIdentityForApply() {
        // pure id <*> v == v
        let value: Result<Int, TestError> = .success(5)
        let identity = Result<@Sendable (Int) -> Int, TestError>.pure(id)
        #expect(Result.apply(identity, value) == value)
    }
}
