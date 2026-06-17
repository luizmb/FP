@testable import CoreFP
import Testing

// MARK: - Fixtures

private struct Player: Sendable {
    var name: String
    var score: Int
}

@Suite("Traversal")
struct TraversalTests {
    @Test func arrayEachGetAllAndOver() {
        let each = [Int].each
        #expect(each.getAll([10, 20, 30]) == [10, 20, 30])
        #expect(each.over { $0 * 2 }([10, 20, 30]) == [20, 40, 60])
        #expect(each.getAll([]) == [])
    }

    @Test func arrayEachModifyMutIsInPlace() {
        var xs = [1, 2, 3]
        [Int].each.modifyMut(&xs) { $0 += 100 }
        #expect(xs == [101, 102, 103])
    }

    @Test func setAllReplacesEveryFocus() {
        #expect([Int].each.setAll([1, 2, 3], 0) == [0, 0, 0])
    }

    @Test func dictionaryEachValue() {
        let t = [String: Int].eachValue
        #expect(Set(t.getAll(["a": 1, "b": 2])) == [1, 2])
        #expect(t.over { $0 + 1 }(["a": 1, "b": 2]) == ["a": 2, "b": 3])
    }

    @Test func liftEndoMutRunsOnEveryFocus() {
        let bump: EndoMut<[Int]> = [Int].each.lift(EndoMut { $0 += 1 })
        var xs = [1, 2, 3]
        bump(&xs)
        #expect(xs == [2, 3, 4])
    }

    @Test func idTraversalHasSingleFocus() {
        let t = Traversal<Int, Int>.id
        #expect(t.getAll(7) == [7])
        #expect(t.over { $0 + 1 }(7) == 8)
    }

    @Test func widenLensToTraversal() {
        let t = lens(\Player.score).traversal
        #expect(t.getAll(Player(name: "A", score: 5)) == [5])
        #expect(t.over { $0 * 10 }(Player(name: "A", score: 5)).score == 50)
    }
}

@Suite("IndexedTraversal")
struct IndexedTraversalTests {
    @Test func arrayEachIndexedTagsPositions() {
        let pairs = [String].eachIndexed.getAll(["a", "b", "c"])
        #expect(pairs.map(\.0) == [0, 1, 2])
        #expect(pairs.map(\.1) == ["a", "b", "c"])
    }

    @Test func indexAwareOver() {
        // Zero out every element except index 1.
        let result = [Int].eachIndexed.over { idx, value in idx == 1 ? value : 0 }([5, 6, 7])
        #expect(result == [0, 6, 0])
    }

    @Test func dictEachValueIndexedTagsKeys() {
        let result = [String: Int].eachValueIndexed.over { key, v in key == "a" ? v : 0 }(["a": 1, "b": 2])
        #expect(result == ["a": 1, "b": 0])
    }

    @Test func dropIndexToPlainTraversal() {
        #expect([Int].eachIndexed.traversal.getAll([1, 2, 3]) == [1, 2, 3])
    }

    @Test func composePreservesOuterIndex() {
        // [Player].eachIndexed >>> score-lens keeps the element position as the index.
        let scores = [Player].eachIndexed.compose(lens(\Player.score).traversal)
        let roster = [Player(name: "A", score: 1), Player(name: "B", score: 2)]
        #expect(scores.getAll(roster).map(\.0) == [0, 1])
        #expect(scores.getAll(roster).map(\.1) == [1, 2])
        let bumped = scores.over { idx, v in v + idx }(roster)
        #expect(bumped.map(\.score) == [1, 3])
    }
}
