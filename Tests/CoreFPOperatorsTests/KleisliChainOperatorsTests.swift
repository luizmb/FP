// SPDX-License-Identifier: Apache-2.0
import CoreFP
import CoreFPOperators
import Testing

// `>=>` / `<=<` return `@Sendable` functions, so three or more arrows chain.
// Before, the composed value was a plain function and could not be fed back
// into another `>=>`, which takes `@Sendable` arguments.

@Suite("Kleisli chains of three arrows")
struct KleisliChainOperatorsTests {
    @Test func optionalChain() {
        let half: @Sendable (Int) -> Int? = { $0.isMultiple(of: 2) ? $0 / 2 : nil }
        let quarterThenEighth = half >=> half >=> half
        #expect(quarterThenEighth(16) == 2)
        #expect(quarterThenEighth(12) == nil)
        #expect((half <=< half <=< half)(16) == 2)
    }

    @Test func arrayChain() {
        let around: @Sendable (Int) -> [Int] = { [$0 - 1, $0 + 1] }
        #expect((around >=> around >=> around)(0).count == 8)
        #expect((around <=< around <=< around)(0).count == 8)
    }

    @Test func resultChain() throws {
        struct Odd: Error {}
        let half: @Sendable (Int) -> Result<Int, Odd> = { $0.isMultiple(of: 2) ? .success($0 / 2) : .failure(Odd()) }
        #expect(try (half >=> half >=> half)(16).get() == 2)
        #expect((half >=> half >=> half)(12).isFailure)
    }

    @Test func arrayTOptionalChain() {
        let step: @Sendable (Int) -> [Int?] = { [$0 + 1, $0 > 1 ? nil : $0] }
        let result = (step >=> step >=> step)(0)
        #expect(result.count == 8)
        #expect(result.contains(nil))
    }
}

private extension Result {
    var isFailure: Bool {
        guard case .failure = self else { return false }
        return true
    }
}
