// SPDX-License-Identifier: Apache-2.0
@testable import CoreFP
import Testing

@Suite struct FunctionApplicativeNamedTests {
    private let length: @Sendable (String) -> Int = get(\.count)
    private let shout: @Sendable (String) -> String = { $0.uppercased() }

    @Test func seqRightKeepsRightResult() {
        #expect(seqRight(length, shout)("abc") == "ABC")
    }

    @Test func seqLeftKeepsLeftResult() {
        #expect(seqLeft(length, shout)("abc") == 3)
    }
}
