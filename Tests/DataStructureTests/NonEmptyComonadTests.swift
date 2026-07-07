// SPDX-License-Identifier: Apache-2.0
import DataStructure
import Testing

@Suite struct NonEmptyComonadTests {
    private let three = NonEmpty(head: 1, tail: [2, 3])

    // MARK: - extract

    @Test func extractReturnsHead() {
        #expect(three.extract == 1)
    }

    @Test func extractFreeFunction() {
        #expect(extract(three) == 1)
    }

    // MARK: - duplicate

    @Test func duplicateBuildsAllSuffixes() {
        let dup = three.duplicate
        #expect(dup.head == three)
        #expect(dup.tail == [NonEmpty(head: 2, tail: [3]), NonEmpty(head: 3, tail: [])])
    }

    @Test func duplicateSingleElement() {
        let single = NonEmpty(head: 42)
        let dup = single.duplicate
        #expect(dup.head == single)
        #expect(dup.tail == [])
    }

    @Test func duplicateFreeFunction() {
        let dup = duplicate(three)
        #expect(dup.toArray == [three, NonEmpty(head: 2, tail: [3]), NonEmpty(head: 3, tail: [])])
    }

    // MARK: - extend

    @Test func extendCountsRemainingElementsAtEachFocus() {
        // At each suffix, count how many elements remain from that point on.
        let result = three.extend { $0.count }
        #expect(result.toArray == [3, 2, 1])
    }

    @Test func coflatMapIsAliasForExtend() {
        let result = three.coflatMap { $0.count }
        #expect(result.toArray == [3, 2, 1])
    }

    @Test func extendFreeCurried() {
        let counts = extend { (ne: NonEmpty<Int>) in ne.count }
        #expect(counts(three).toArray == [3, 2, 1])
    }

    @Test func extendCanSumRemainingElements() {
        let result = three.extend { ne in ne.toArray.reduce(0, +) }
        #expect(result.toArray == [6, 5, 3])
    }

    // MARK: - Comonad laws

    // extract . duplicate == id
    @Test func comonadLawExtractDuplicate() {
        #expect(extract(duplicate(three)) == three)
    }

    // fmap extract . duplicate == id
    @Test func comonadLawFmapExtractDuplicate() {
        let result = three.duplicate.map { extract($0) }
        #expect(result == three)
    }

    // extend extract == id
    @Test func comonadLawExtendExtract() {
        #expect(three.extend { extract($0) } == three)
    }
}
