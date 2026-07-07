// SPDX-License-Identifier: Apache-2.0
import CoreFP
@testable import DataStructure
import Foundation
import Testing

// MARK: - Fixtures

private let single = Zipper(focus: 1)
private let middle = Zipper(left: [2, 1], focus: 3, right: [4, 5])

@Suite struct ZipperTests {
    // MARK: - Construction

    @Test func init_focusOnly() {
        let z = Zipper(focus: 42)
        #expect(z.left == [])
        #expect(z.focus == 42)
        #expect(z.right == [])
    }

    @Test func init_leftFocusRight() {
        let z = Zipper(left: [2, 1], focus: 3, right: [4, 5])
        #expect(z.left == [2, 1])
        #expect(z.focus == 3)
        #expect(z.right == [4, 5])
    }

    @Test func init_fromArray_nonEmpty() {
        let z = Zipper([1, 2, 3])
        #expect(z?.focus == 1)
        #expect(z?.left == [])
        #expect(z?.right == [2, 3])
    }

    @Test func init_fromArray_empty() {
        let z = Zipper([Int]())
        #expect(z == nil)
    }

    @Test func freeConstructor_fromArray_nonEmpty() {
        let z = zipper([1, 2, 3])
        #expect(z?.toArray() == [1, 2, 3])
    }

    @Test func freeConstructor_fromArray_empty() {
        let z = zipper([Int]())
        #expect(z == nil)
    }

    // MARK: - Accessors

    @Test func isAtStart() {
        #expect(single.isAtStart)
        #expect(middle.isAtStart == false)
    }

    @Test func isAtEnd() {
        #expect(single.isAtEnd)
        #expect(middle.isAtEnd == false)
    }

    @Test func count() {
        #expect(single.count == 1)
        #expect(middle.count == 5)
    }

    @Test func toArray() {
        #expect(middle.toArray() == [1, 2, 3, 4, 5])
        #expect(single.toArray() == [1])
    }

    // MARK: - Navigation

    @Test func moveLeft_atStart_returnsNil() {
        #expect(single.moveLeft() == nil)
        #expect(Zipper(left: [], focus: 1, right: [2]).moveLeft() == nil)
    }

    @Test func moveRight_atEnd_returnsNil() {
        #expect(single.moveRight() == nil)
        #expect(Zipper(left: [1], focus: 2, right: []).moveRight() == nil)
    }

    @Test func moveLeft_midSequence() {
        let moved = middle.moveLeft()
        #expect(moved?.left == [1])
        #expect(moved?.focus == 2)
        #expect(moved?.right == [3, 4, 5])
        #expect(moved?.toArray() == [1, 2, 3, 4, 5])
    }

    @Test func moveRight_midSequence() {
        let moved = middle.moveRight()
        #expect(moved?.left == [3, 2, 1])
        #expect(moved?.focus == 4)
        #expect(moved?.right == [5])
        #expect(moved?.toArray() == [1, 2, 3, 4, 5])
    }

    @Test func moveLeft_thenMoveRight_isIdentity() {
        let roundTrip = middle.moveLeft()?.moveRight()
        #expect(roundTrip == middle)
    }

    @Test func moveRight_thenMoveLeft_isIdentity() {
        let roundTrip = middle.moveRight()?.moveLeft()
        #expect(roundTrip == middle)
    }

    @Test func moveLeft_toStart() {
        let atStart = middle.moveLeft()?.moveLeft()
        #expect(atStart?.isAtStart == true)
        #expect(atStart?.focus == 1)
        #expect(atStart?.moveLeft() == nil)
    }

    @Test func moveRight_toEnd() {
        let atEnd = middle.moveRight()?.moveRight()
        #expect(atEnd?.isAtEnd == true)
        #expect(atEnd?.focus == 5)
        #expect(atEnd?.moveRight() == nil)
    }

    // MARK: - NonEmpty interop

    @Test func fromNonEmpty() {
        let ne = NonEmpty(head: 1, tail: [2, 3])
        let z = Zipper.fromNonEmpty(ne)
        #expect(z.focus == 1)
        #expect(z.left == [])
        #expect(z.right == [2, 3])
    }

    @Test func toNonEmpty_fromStart() {
        let z = Zipper(left: [], focus: 1, right: [2, 3])
        #expect(z.toNonEmpty() == NonEmpty(head: 1, tail: [2, 3]))
    }

    @Test func toNonEmpty_fromMiddle() {
        #expect(middle.toNonEmpty() == NonEmpty(head: 1, tail: [2, 3, 4, 5]))
    }

    @Test func nonEmpty_roundTrip() {
        let ne = NonEmpty(head: 1, tail: [2, 3])
        #expect(Zipper.fromNonEmpty(ne).toNonEmpty() == ne)
    }

    // MARK: - Functor

    @Test func map() {
        #expect(middle.map { $0 * 10 }.toArray() == [10, 20, 30, 40, 50])
    }

    @Test func map_preservesFocusPosition() {
        let mapped = middle.map { $0 * 0 }
        #expect(mapped.left == [0, 0])
        #expect(mapped.focus == 0)
        #expect(mapped.right == [0, 0])
    }

    @Test func fmap_static() {
        let double = Zipper<Int>.fmap { $0 * 2 }
        #expect(double(middle).toArray() == [2, 4, 6, 8, 10])
    }

    // MARK: - Functor laws

    @Test func functorLaw_identity() {
        #expect(middle.map(id) == middle)
    }

    @Test func functorLaw_composition() {
        let f: @Sendable (Int) -> Int = { $0 + 1 }
        let g: @Sendable (Int) -> Int = { $0 * 2 }
        #expect(middle.map(compose(f, g)) == middle.map(f).map(g))
    }

    // MARK: - Comonad

    @Test func extract_returnsFocus() {
        #expect(middle.extract == 3)
        #expect(extract(middle) == 3)
    }

    @Test func duplicate_focusIsSelf() {
        #expect(middle.duplicate().focus == middle)
    }

    @Test func duplicate_positionsInOrder() {
        // middle is focused on the 3rd of 5 elements: [1, 2, 3, 4, 5]
        let positions = middle.duplicate().toArray().map(\.focus)
        #expect(positions == [1, 2, 3, 4, 5])
    }

    @Test func duplicate_leftAndRightCounts() {
        let dup = middle.duplicate()
        #expect(dup.left.count == 2)
        #expect(dup.right.count == 2)
    }

    @Test func duplicate_atStart() {
        let z = Zipper(left: [], focus: 1, right: [2, 3])
        let dup = z.duplicate()
        #expect(dup.left == [])
        #expect(dup.right.map(\.focus) == [2, 3])
    }

    @Test func duplicate_atEnd() {
        let z = Zipper(left: [2, 1], focus: 3, right: [])
        let dup = z.duplicate()
        #expect(dup.left.map(\.focus) == [2, 1])
        #expect(dup.right == [])
    }

    @Test func duplicate_singleElement() {
        let dup = single.duplicate()
        #expect(dup.left == [])
        #expect(dup.right == [])
        #expect(dup.focus == single)
    }

    @Test func extend() {
        let sums = middle.extend { z in z.left.reduce(0, +) + z.focus + z.right.reduce(0, +) }
        #expect(sums.toArray() == [15, 15, 15, 15, 15])
    }

    @Test func extend_static() {
        let extendFn = Zipper<Int>.extend { $0.focus }
        #expect(extendFn(middle) == middle.map(id))
    }

    @Test func coflatMap_matchesExtend() {
        let fn: @Sendable (Zipper<Int>) -> Int = { $0.focus * 100 }
        #expect(middle.coflatMap(fn) == middle.extend(fn))
    }

    // MARK: - Comonad laws

    @Test func comonadLaw_extractDuplicate() {
        #expect(extract(duplicate(middle)) == middle)
    }

    @Test func comonadLaw_mapExtractDuplicate() {
        let result = duplicate(middle).map(\.extract)
        #expect(result == middle)
        #expect(result.toArray() == middle.toArray())
    }
}
