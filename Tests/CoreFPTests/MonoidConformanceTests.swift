// SPDX-License-Identifier: Apache-2.0
@testable import CoreFP
import Testing

@Suite struct MonoidConformanceTests {
    @Test func stringMonoid() {
        #expect(String.identity == "")
        #expect(String.combine(String.identity, "hello") == "hello")
        #expect(String.combine("hello", String.identity) == "hello")
    }

    @Test func arrayMonoid() {
        #expect([Int].identity == [])
        #expect([Int].combine([Int].identity, [1, 2]) == [1, 2])
        #expect([Int].combine([1, 2], [Int].identity) == [1, 2])
    }

    @Test func setMonoid() {
        #expect(Set<Int>.identity == [])
        #expect(Set<Int>.combine(Set<Int>.identity, [1, 2]) == [1, 2])
    }

    @Test func dictionaryMonoid() {
        #expect([String: Int].identity == [:])
        #expect([String: Int].combine([String: Int].identity, ["a": 1]) == ["a": 1])
    }

    @Test func foldWithMconcat() {
        let strings = mconcat(["foo", "bar", "baz"])
        let emptyString = mconcat([String]())
        let arrays = mconcat([[1, 2], [3], [4, 5]])
        #expect(strings == "foobarbaz")
        #expect(emptyString == "")
        #expect(arrays == [1, 2, 3, 4, 5])
    }

    @Test func foldWithSconcat() {
        let strings = sconcat("foo", ["bar", "baz"])
        let arrays = sconcat([1, 2], [[3], [4, 5]])
        #expect(strings == "foobarbaz")
        #expect(arrays == [1, 2, 3, 4, 5])
    }

    // MARK: - mconcat / sconcat customization point

    @Test func freeMconcatDispatchesToTypeOverride() {
        let result = mconcat([MconcatDirect(parts: ["a"]), MconcatDirect(parts: ["b"])])
        #expect(result.viaCustomMconcat)   // the free function reached the type's override
        #expect(result.parts == ["a", "b"])
    }

    @Test func defaultMconcatDelegatesToSconcatOverride() {
        // SconcatOnly overrides only `sconcat`; the default `mconcat` must route through it.
        let result = mconcat([SconcatOnly(parts: ["a"]), SconcatOnly(parts: ["b"]), SconcatOnly(parts: ["c"])])
        #expect(result.viaCustomSconcat)
        #expect(result.parts == ["a", "b", "c"])
    }

    @Test func freeSconcatDispatchesToTypeOverride() {
        let result = sconcat(SconcatOnly(parts: ["x"]), [SconcatOnly(parts: ["y"])])
        #expect(result.viaCustomSconcat)
        #expect(result.parts == ["x", "y"])
    }

    @Test func emptyMconcatReturnsIdentityWithoutFolding() {
        let result = mconcat([SconcatOnly]())
        #expect(result == SconcatOnly.identity)
        #expect(result.viaCustomSconcat == false)   // sconcat is never invoked for []
    }

    @Test func arrayAndStringRouteThroughSinglePassOverrides() {
        // Behavioural parity with the previous left fold (now via the O(n) overrides).
        #expect(mconcat([[1, 2], [3], [4, 5]]) == [1, 2, 3, 4, 5])
        #expect(mconcat(["foo", "bar", "baz"]) == "foobarbaz")
        #expect(sconcat([1], [[2], [3]]) == [1, 2, 3])
        #expect(mconcat([[Int]]()) == [])
    }
}

// MARK: - Customization-point fixtures

// Overrides only `sconcat`; its `mconcat` must arrive via the default's delegation.
private struct SconcatOnly: Monoid, Equatable {
    var parts: [String]
    var viaCustomSconcat = false
    static var identity: SconcatOnly { SconcatOnly(parts: []) }
    static func combine(_ lhs: SconcatOnly, _ rhs: SconcatOnly) -> SconcatOnly {
        SconcatOnly(parts: lhs.parts + rhs.parts)
    }
    static func sconcat(_ first: SconcatOnly, _ rest: [SconcatOnly]) -> SconcatOnly {
        SconcatOnly(parts: rest.reduce(first.parts) { $0 + $1.parts }, viaCustomSconcat: true)
    }
}

// Overrides `mconcat` directly.
private struct MconcatDirect: Monoid, Equatable {
    var parts: [String]
    var viaCustomMconcat = false
    static var identity: MconcatDirect { MconcatDirect(parts: []) }
    static func combine(_ lhs: MconcatDirect, _ rhs: MconcatDirect) -> MconcatDirect {
        MconcatDirect(parts: lhs.parts + rhs.parts)
    }
    static func mconcat(_ values: [MconcatDirect]) -> MconcatDirect {
        MconcatDirect(parts: values.flatMap(\.parts), viaCustomMconcat: true)
    }
}
