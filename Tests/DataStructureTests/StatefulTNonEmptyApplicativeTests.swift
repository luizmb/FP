// SPDX-License-Identifier: Apache-2.0
import DataStructure
import Testing

@Suite struct StatefulTNonEmptyApplicativeTests {
    // MARK: - apply

    @Test func applyCombinesFunctionsAndValues() {
        let sf = Stateful<Int, NonEmpty<@Sendable (Int) -> String>> { state in
            state += 1
            return NonEmpty(head: { "\($0)a" }, tail: [{ "\($0)b" }])
        }
        let sa = Stateful<Int, NonEmpty<Int>> { state in
            state += 10
            return NonEmpty(head: 1, tail: [2])
        }
        var state = 0
        let result = StatefulTNonEmpty.apply(sf.statefulT, sa.statefulT).rawValue.run(&state)
        #expect(result == NonEmpty(head: "1a", tail: ["2a", "1b", "2b"]))
        #expect(state == 11)
    }

    // MARK: - liftA2

    @Test func liftA2CombinesElementwise() {
        let sa = Stateful<Int, NonEmpty<Int>> { state in
            state += 1
            return NonEmpty(head: 1, tail: [2])
        }
        let sb = Stateful<Int, NonEmpty<Int>> { state in
            state += 100
            return NonEmpty(head: 10, tail: [20])
        }
        var state = 0
        let result = StatefulTNonEmpty.liftA2 { (a: Int, b: Int) in a + b }(sa.statefulT, sb.statefulT).rawValue.run(&state)
        #expect(result == NonEmpty(head: 11, tail: [21, 12, 22]))
        #expect(state == 101)
    }

    // MARK: - seqRight / seqLeft

    @Test func seqRightKeepsRightValue() {
        let lhs = Stateful<Int, NonEmpty<Int>> { state in
            state += 1
            return NonEmpty(head: 1)
        }
        let rhs = Stateful<Int, NonEmpty<String>> { state in
            state += 10
            return NonEmpty(head: "b")
        }
        var state = 0
        let result = lhs.statefulT.seqRight(rhs.statefulT).rawValue.run(&state)
        #expect(result == NonEmpty(head: "b"))
        #expect(state == 11)
    }

    @Test func seqLeftKeepsLeftValue() {
        let lhs = Stateful<Int, NonEmpty<Int>> { state in
            state += 1
            return NonEmpty(head: 1)
        }
        let rhs = Stateful<Int, NonEmpty<String>> { state in
            state += 10
            return NonEmpty(head: "b")
        }
        var state = 0
        let result = lhs.statefulT.seqLeft(rhs.statefulT).rawValue.run(&state)
        #expect(result == NonEmpty(head: 1))
        #expect(state == 11)
    }
}
