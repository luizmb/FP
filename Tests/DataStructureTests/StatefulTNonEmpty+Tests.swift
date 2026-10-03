// SPDX-License-Identifier: Apache-2.0
import DataStructure
import Testing

@Suite struct StatefulTNonEmptyTests {
    // MARK: - Stateful<S, NonEmpty<A>> — mapT (functor)

    @Test func mapT() {
        let s = Stateful<Int, NonEmpty<Int>>.pure(NonEmpty(head: 1, tail: [2, 3]))
        let mapped = s.mapT { $0 * 2 }
        #expect(mapped.eval(0) == NonEmpty(head: 2, tail: [4, 6]))
    }

    @Test func fmapT_curried() {
        let s = Stateful<Int, NonEmpty<Int>>.pure(NonEmpty(head: 5))
        let mapped = Stateful<Int, NonEmpty<Int>>.fmapT { $0 + 1 }(s)
        #expect(mapped.eval(0) == NonEmpty(head: 6))
    }
}
