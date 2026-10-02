// SPDX-License-Identifier: Apache-2.0
// swiftlint:disable discouraged_optional_collection
import CoreFP
import Foundation
import Testing

// Pins the properties the O(n) / in-place rewrites rely on: early exit, single-pass folds that
// agree with the pairwise definition, and optics that mutate the focused buffer in place.

private struct Holder { var items: [Int] }

private func address(_ array: [Int]) -> UnsafePointer<Int>? {
    array.withUnsafeBufferPointer(\.baseAddress)
}

// Test-only call counter; every access goes through `lock`.
private final class Calls: @unchecked Sendable {
    private let lock = NSLock()
    private var value = 0
    var count: Int { lock.withLock { value } }
    func tick() { lock.withLock { value += 1 } }
}

@Suite("Performance rewrites keep semantics")
struct PerformanceRegressionTests {
    @Test func optionalTraverseStopsAtFirstNil() {
        let calls = Calls()
        let result = [1, 2, 3, 4].traverse { (x: Int) -> Int? in calls.tick(); return x == 2 ? nil : x }
        #expect(result == nil)
        #expect(calls.count == 2)
        #expect([1, 2, 3].traverse { Optional($0 * 10) } == [10, 20, 30])
    }

    @Test func resultTraverseStopsAtFirstFailure() {
        struct Bad: Error, Equatable { let at: Int }
        let calls = Calls()
        let result = [1, 2, 3].traverse { (x: Int) -> Result<Int, Bad> in calls.tick(); return x == 2 ? .failure(Bad(at: x)) : .success(x) }
        #expect(result == .failure(Bad(at: 2)))
        #expect(calls.count == 2)
    }

    @Test func optionalTArrayBindConcatenatesInOrderAndStopsAtNil() {
        let chunks: [Int]? = [1, 2]
        #expect(chunks.flatMapT { [$0, $0 * 10] } == [1, 10, 2, 20])
        #expect(chunks.flatMapT { $0 == 1 ? nil : [$0] } == nil)
    }

    @Test func setSconcatMatchesPairwiseUnion() {
        let sets: [Set<Int>] = [[1, 2], [2, 3], [4]]
        #expect(Set.sconcat([0], sets) == sets.reduce([0], Set.combine))
    }

    @Test func dictionarySconcatIsRightBiasedLikeCombine() {
        let dicts: [[String: Int]] = [["a": 1, "b": 1], ["b": 2], ["c": 3]]
        let expected = dicts.reduce(["a": 0], [String: Int].combine)
        #expect([String: Int].sconcat(["a": 0], dicts) == expected)
        #expect(expected == ["a": 1, "b": 2, "c": 3])
    }

    @Test func lensTraversalMutatesInPlace() {
        var holder = Holder(items: Array(0..<1_000))
        let before = address(holder.items)
        lens(\Holder.items).traversal.modifyMut(&holder) { $0[0] = 42 }
        #expect(holder.items[0] == 42)
        #expect(address(holder.items) == before)
    }

    @Test func dictionaryEachValueMutatesInPlace() {
        var dict = ["a": Array(0..<1_000)]
        let before = dict["a"].flatMap(address)
        [String: [Int]].eachValue.modifyMut(&dict) { $0[0] = 42 }
        #expect(dict["a"]?.first == 42)
        #expect(dict["a"].flatMap(address) == before)
    }

    @Test func dictionaryEachValueIndexedPassesMatchingKeys() {
        let result = [String: Int].eachValueIndexed.over { key, value in key == "a" ? value : 0 }(["a": 1, "b": 2])
        #expect(result == ["a": 1, "b": 0])
    }
}

// swiftlint:enable discouraged_optional_collection
