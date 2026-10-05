// SPDX-License-Identifier: Apache-2.0
import DataStructure
import Testing

@Suite struct StatefulTNonEmptyTests {
    // MARK: - StatefulTNonEmpty — map (functor)

    @Test func map() {
        let s = Stateful<Int, NonEmpty<Int>>.pure(NonEmpty(head: 1, tail: [2, 3]))
        let mapped = s.statefulT.map { $0 * 2 }
        #expect(mapped.rawValue.eval(0) == NonEmpty(head: 2, tail: [4, 6]))
    }

    @Test func fmapCurried() {
        let s = Stateful<Int, NonEmpty<Int>>.pure(NonEmpty(head: 5))
        let mapped = StatefulTNonEmpty<Int, Int>.fmap { $0 + 1 }(s.statefulT)
        #expect(mapped.rawValue.eval(0) == NonEmpty(head: 6))
    }
}
