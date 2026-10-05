// SPDX-License-Identifier: Apache-2.0
import DataStructure
import Testing

@Suite struct StatefulTArrayTests {
    // MARK: - Stateful<S, [A]> — State as outer, Array as inner

    @Test func map() {
        let s = Stateful<Int, [Int]>.pure([1, 2, 3])
        let mapped = s.statefulT.map { $0 * 2 }
        #expect(mapped.rawValue.eval(0) == [2, 4, 6])
    }

    @Test func mapEmpty() {
        let s = Stateful<Int, [Int]>.pure([])
        let mapped = s.statefulT.map { $0 * 2 }
        #expect(mapped.rawValue.eval(0) == [])
    }

    // MARK: - [Stateful<S, A>] — Array as outer, Stateful as inner

    @Test func arrayTStatefulMapT() {
        let arr: [Stateful<Int, Int>] = [
            .pure(1),
            .pure(2),
            .pure(3)
        ]
        let mapped = arr.arrayT.map { $0 * 10 }.rawValue
        let results = mapped.map { $0.eval(0) }
        #expect(results == [10, 20, 30])
    }
}
