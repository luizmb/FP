// SPDX-License-Identifier: Apache-2.0
import CoreFP
import Testing

private struct Frame: Mutable, Equatable { var x = 0; var width = 0 }

@Suite("castOptionally and Mutable.mutate")
struct CastAndMutableTests {
    @Test func castOptionallyNarrowsFromAny() {
        let mixed: [Any] = [1, "two", 3]
        #expect(mixed.compactMap(castOptionally(Int.self)) == [1, 3])
    }

    @Test func castOptionallyFailsForOtherTypes() {
        let toString: (Any) -> String? = castOptionally(String.self)
        #expect(toString(42) == nil)
        #expect(toString("ok") == "ok")
    }

    @Test func mutateReturnsTheMutatedCopy() {
        let original = Frame()
        let moved = original.mutate { $0.x = 10 }
        #expect(moved == Frame(x: 10, width: 0))
        #expect(original == Frame())
    }

    @Test func mutateWithPureFunction() {
        #expect(Frame().mutate { Frame(x: $0.x, width: 5) } == Frame(x: 0, width: 5))
    }
}
