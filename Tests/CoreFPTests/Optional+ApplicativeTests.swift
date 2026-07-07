// SPDX-License-Identifier: Apache-2.0
@testable import CoreFP
import Testing

@Suite struct OptionalCoreApplicativeTests {
    // MARK: - pure

    @Test func pureLiftsIntoSome() {
        let result: Int? = Optional.pure(42)
        #expect(result == 42)
    }

    @Test func pureIsLeftIdentityForApply() {
        // pure id <*> v == v
        let value: Int? = 5
        let identity = (@Sendable (Int) -> Int)?.pure(id)
        #expect(Optional.apply(identity, value) == value)
    }
}
