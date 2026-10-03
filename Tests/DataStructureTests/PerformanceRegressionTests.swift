// SPDX-License-Identifier: Apache-2.0
import CoreFP
import DataStructure
import Testing

// Pins the properties the O(n) / in-place rewrites rely on: single-pass folds that agree with the
// pairwise definition, error/log order, early exit, and zoom mutating the focus in place.

private struct Holder { var items: [Int] }

private func address(_ array: [Int]) -> UnsafePointer<Int>? {
    array.withUnsafeBufferPointer(\.baseAddress)
}

@Suite("Performance rewrites keep semantics (DataStructure)")
struct DataStructurePerformanceRegressionTests {
    @Test func nonEmptySconcatMatchesPairwiseCombine() {
        let first = NonEmpty(head: 1, tail: [2])
        let rest = [NonEmpty(head: 3), NonEmpty(head: 4, tail: [5, 6])]
        #expect(NonEmpty.sconcat(first, rest) == rest.reduce(first, NonEmpty.combine))
        #expect(NonEmpty.sconcat(first, rest).toArray == [1, 2, 3, 4, 5, 6])
    }

    @Test func validationTraverseAccumulatesErrorsInOrder() {
        let check: (Int) -> Validation<[String], Int> = { $0.isMultiple(of: 2) ? .failure(["odd? no: \($0)"]) : .success($0) }
        let result = NonEmpty(head: 2, tail: [1, 4, 3, 6]).traverse(check)
        #expect(result == .failure(["odd? no: 2", "odd? no: 4", "odd? no: 6"]))
    }

    @Test func validationTraverseSucceedsWithAllValues() {
        let result = NonEmpty(head: 1, tail: [3, 5]).traverse { Validation<[String], Int>.success($0 * 2) }
        #expect(result == .success(NonEmpty(head: 2, tail: [6, 10])))
    }

    @Test func validationTraverseHeadFailureComesFirst() {
        let check: (Int) -> Validation<[String], Int> = { $0 > 0 ? .success($0) : .failure(["\($0)"]) }
        #expect(NonEmpty(head: -1, tail: [2, -3]).traverse(check) == .failure(["-1", "-3"]))
    }

    @Test func writerTArrayLogOrderIsPreserved() {
        let start = [Writer(1, ["a"]), Writer(2, ["b"])]
        let result = start.flatMapT { Writer($0 * 10, ["f\($0)"]) }
        #expect(result.map(\.log) == [["a", "f1"], ["b", "f2"]])
    }

    @Test func lensZoomMutatesInPlace() {
        var holder = Holder(items: Array(0..<1_000))
        let before = address(holder.items)
        let count = lens(\Holder.items).zoom(Stateful<[Int], Int> { items in items[0] = 42; return items.count })
            .run(&holder)
        #expect(count == 1_000)
        #expect(holder.items[0] == 42)
        #expect(address(holder.items) == before)
    }

    @Test func affineZoomOnAbsentFocusIsNil() {
        struct Box { var maybe: Int? }
        var box = Box(maybe: nil)
        #expect(affineTraversal(\Box.maybe).zoom(Stateful<Int, Int> { $0 += 1; return $0 }).run(&box) == nil)
        #expect(box.maybe == nil)
    }
}
