// SPDX-License-Identifier: Apache-2.0
@testable import CoreFP
import Testing

// `forEach` is the fold primitive every traversal carries. The law checked throughout: visiting
// the foci with `forEach` yields exactly `getAll`, in the same order, for base traversals and for
// every composition pairing (each composition builds its `getAll` differently).

// MARK: - Fixtures

private struct Member: Sendable, Equatable {
    var name: String
    var nickname: String?
}

private struct Team: Sendable, Equatable {
    var members: [Member]
}

private enum Slot: Sendable, Equatable {
    case empty
    case filled([Int])
}

private struct Celsius: Sendable, Equatable {
    var degrees: Double
}

private let filledPrism: Prism<Slot, [Int]> = prism(
    preview: { if case let .filled(values) = $0 { values } else { nil } },
    review: Slot.filled
)
private let celsiusIso: Iso<Celsius, Double> = iso(get: \.degrees, reverseGet: Celsius.init)

private let teams = [
    Team(members: [Member(name: "Ana", nickname: "A"), Member(name: "Bo", nickname: nil)]),
    Team(members: []),
    Team(members: [Member(name: "Cy", nickname: "C")])
]

/// Collects the foci through `forEach`, to compare against `getAll`.
private func visited<S, A>(_ traversal: Traversal<S, A>, _ whole: S) -> [A] {
    var all: [A] = []
    traversal.forEach(whole) { all.append($0) }
    return all
}

private func visitedIndexed<S, I, A>(_ traversal: IndexedTraversal<S, I, A>, _ whole: S) -> [(I, A)] {
    var all: [(I, A)] = []
    traversal.forEach(whole) { all.append(($0, $1)) }
    return all
}

// MARK: - forEach on base traversals

@Suite("Traversal fold — base traversals")
struct TraversalFoldBaseTests {
    @Test func arrayEachVisitsInOrder() {
        #expect(visited([Int].each, [3, 1, 2]) == [3, 1, 2])
        #expect(visited([Int].each, []) == [])
    }

    @Test func arraySliceEachVisitsTheSlice() {
        let slice = Array(0 ..< 10)[4 ..< 7]
        #expect(visited([Int].SubSequence.each, slice) == [4, 5, 6])
    }

    @Test func nonContiguousCollectionFallsBackToIteration() {
        var table = ["a": 1, "b": 2, "c": 3]
        let values = [String: Int].Values.each
        #expect(visited(values, table.values) == Array(table.values))
        values.modifyMut(&table.values) { $0 *= 10 }
        #expect(table == ["a": 10, "b": 20, "c": 30])
    }

    @Test func dictionaryEachValueVisitsEveryValue() {
        let table = ["a": 1, "b": 2]
        #expect(visited([String: Int].eachValue, table) == [String: Int].eachValue.getAll(table))
    }

    @Test func widenedOpticsVisitTheirFocus() {
        #expect(visited(lens(\Member.name).traversal, Member(name: "Ana")) == ["Ana"])
        #expect(visited(filledPrism.traversal, .filled([1])) == [[1]])
        #expect(visited(filledPrism.traversal, .empty) == [])
        #expect(visited(affineTraversal(\Member.nickname).traversal, Member(name: "Bo")) == [])
        #expect(visited(celsiusIso.traversal, Celsius(degrees: 21)) == [21])
        #expect(visited(Traversal<Int, Int>.id, 7) == [7])
    }
}

// MARK: - Inits

@Suite("Traversal fold — inits")
struct TraversalFoldInitTests {
    @Test func arrayFirstInitDerivesForEachFromGetAll() {
        let evens = Traversal<[Int], Int>(
            getAll: { $0.filter { $0.isMultiple(of: 2) } },
            modifyMut: { xs, f in for i in xs.indices where xs[i].isMultiple(of: 2) {
                f(&xs[i])
            } }
        )
        #expect(visited(evens, [1, 2, 3, 4]) == [2, 4])
    }

    @Test func foldFirstInitDerivesGetAllFromForEach() {
        let evens = Traversal<[Int], Int>(
            forEach: { xs, body in for x in xs where x.isMultiple(of: 2) {
                body(x)
            } },
            modifyMut: { xs, f in for i in xs.indices where xs[i].isMultiple(of: 2) {
                f(&xs[i])
            } }
        )
        #expect(evens.getAll([1, 2, 3, 4]) == [2, 4])
        #expect(evens.over { $0 * 10 }([1, 2, 3, 4]) == [1, 20, 3, 40])
    }
}

// MARK: - forEach matches getAll through every composition

@Suite("Traversal fold — composition")
struct TraversalFoldCompositionTests {
    private let names = [Team].each.compose(lens(\Team.members)).compose([Member].each).compose(lens(\Member.name))

    @Test func traversalThenTraversal() {
        let grid = [[1, 2], [], [3]]
        let cells = [[Int]].each.compose([Int].each)
        #expect(cells.getAll(grid) == [1, 2, 3])
        #expect(visited(cells, grid) == [1, 2, 3])
    }

    @Test func traversalThenLens() {
        #expect(names.getAll(teams) == ["Ana", "Bo", "Cy"])
        #expect(visited(names, teams) == names.getAll(teams))
    }

    @Test func traversalThenAffineSkipsMisses() {
        let nicknames = [Member].each.compose(affineTraversal(\Member.nickname))
        let members = teams.flatMap(\.members)
        #expect(nicknames.getAll(members) == ["A", "C"])
        #expect(visited(nicknames, members) == ["A", "C"])
    }

    @Test func traversalThenPrismSkipsMisses() {
        let filled = [Slot].each.compose(filledPrism)
        let slots: [Slot] = [.filled([1]), .empty, .filled([2, 3])]
        #expect(filled.getAll(slots) == [[1], [2, 3]])
        #expect(visited(filled, slots) == [[1], [2, 3]])
    }

    @Test func traversalThenIso() {
        let degrees = [Celsius].each.compose(celsiusIso)
        let readings = [Celsius(degrees: 1), Celsius(degrees: 2)]
        #expect(degrees.getAll(readings) == [1, 2])
        #expect(visited(degrees, readings) == [1, 2])
    }

    @Test func lensThenTraversal() {
        let members = lens(\Team.members).compose([Member].each)
        #expect(members.getAll(teams[0]) == teams[0].members)
        #expect(visited(members, teams[0]) == teams[0].members)
    }

    @Test func isoThenTraversal() {
        let digits = iso(
            get: { (n: Int) in String(n).compactMap(\.wholeNumberValue) },
            reverseGet: { Int($0.map(String.init).joined()) ?? 0 }
        )
        .compose([Int].each)
        #expect(digits.getAll(407) == [4, 0, 7])
        #expect(visited(digits, 407) == [4, 0, 7])
    }

    @Test func prismThenTraversalHitAndMiss() {
        let values = filledPrism.compose([Int].each)
        #expect(values.getAll(.filled([5, 6])) == [5, 6])
        #expect(visited(values, .filled([5, 6])) == [5, 6])
        #expect(values.getAll(.empty) == [])
        #expect(visited(values, .empty) == [])
    }

    @Test func affineThenTraversalHitAndMiss() {
        let letters = affineTraversal(\Member.nickname).compose(Traversal<String, Character>(
            forEach: { s, body in for c in s {
                body(c)
            } },
            modifyMut: { s, f in s = String(s.map { c in var c = c; f(&c); return c }) }
        ))
        #expect(letters.getAll(Member(name: "Ana", nickname: "Al")) == ["A", "l"])
        #expect(visited(letters, Member(name: "Ana", nickname: "Al")) == ["A", "l"])
        #expect(visited(letters, Member(name: "Bo")) == [])
    }

    @Test func compositionStillWritesThroughModifyMut() {
        #expect(names.over { $0.uppercased() }(teams).flatMap(\.members).map(\.name) == ["ANA", "BO", "CY"])
    }
}

// MARK: - Folds

@Suite("Traversal fold — reduce, foldMap, count")
struct TraversalFoldMethodTests {
    private let nameLengths = [Team].each.compose(lens(\Team.members)).compose([Member].each).compose(lens(\Member.name))

    @Test func reduceIntoAccumulatesInOrder() {
        let joined = nameLengths.reduce(teams, into: "") { acc, name in acc += name }
        #expect(joined == "AnaBoCy")
    }

    @Test func reduceIntoOnNoFociReturnsTheInitialValue() {
        #expect([Int].each.reduce([], into: 42) { $0 += $1 } == 42)
    }

    @Test func foldMapCombinesThroughTheMonoid() {
        let total = [Team].each.compose(lens(\Team.members)).foldMap(teams) { Int.Monoids.Sum($0.count) }
        #expect(total.rawValue == 3)
    }

    @Test func foldMapOnNoFociIsTheIdentity() {
        #expect([Int].each.foldMap([]) { Int.Monoids.Sum($0) }.rawValue == 0)
    }

    @Test func countMatchesGetAll() {
        #expect(nameLengths.count(teams) == nameLengths.getAll(teams).count)
        #expect([Int].each.count([]) == 0)
        #expect(filledPrism.traversal.count(.empty) == 0)
    }
}

// MARK: - IndexedTraversal

@Suite("IndexedTraversal fold")
struct IndexedTraversalFoldTests {
    @Test func eachIndexedVisitsPositions() {
        let pairs = visitedIndexed([String].eachIndexed, ["a", "b"])
        #expect(pairs.map(\.0) == [0, 1])
        #expect(pairs.map(\.1) == ["a", "b"])
    }

    @Test func eachValueIndexedVisitsKeys() {
        let table = ["a": 1, "b": 2]
        let pairs = visitedIndexed([String: Int].eachValueIndexed, table)
        #expect(Dictionary(uniqueKeysWithValues: pairs) == table)
    }

    @Test func composedIndexedKeepsTheOuterIndex() {
        let names = [Member].eachIndexed.compose(lens(\Member.name))
        let members = teams[0].members
        #expect(names.getAll(members).map(\.0) == [0, 1])
        #expect(visitedIndexed(names, members).map(\.1) == ["Ana", "Bo"])
    }

    @Test func dropIndexVisitsTheFoci() {
        #expect(visited([String].eachIndexed.traversal, ["x", "y"]) == ["x", "y"])
    }

    @Test func indexedReduceSeesIndexAndFocus() {
        let weighted = [Int].eachIndexed.reduce([10, 20, 30], into: 0) { acc, index, value in acc += index * value }
        #expect(weighted == 80)
    }

    @Test func arrayFirstInitDerivesForEach() {
        let odds = IndexedTraversal<[Int], Int, Int>(
            getAll: { xs in xs.indices.filter { !xs[$0].isMultiple(of: 2) }.map { ($0, xs[$0]) } },
            modifyMut: { xs, f in for i in xs.indices where !xs[i].isMultiple(of: 2) {
                f(i, &xs[i])
            } }
        )
        #expect(visitedIndexed(odds, [1, 2, 3]).map(\.0) == [0, 2])
    }
}
