import CoreFP
import DataStructure
import Testing

// MARK: - Fixtures

private struct Address {
    var street: String
}

private struct AppState {
    var count: Int
    var address: Address
    var items: [Int]
}

private enum Route {
    case home(Int)
    case other

    var homeValue: Int? {
        guard case .home(let v) = self else { return nil }
        return v
    }
}

// MARK: - Lens.zoom

@Suite("Lens.zoom")
struct LensZoomTests {
    private let countLens = lens(\AppState.count)
    private let addressLens = lens(\AppState.address)
    private let streetLens = lens(\Address.street)

    private let initial = AppState(count: 0, address: Address(street: "1st Ave"), items: [1, 2, 3])

    @Test func zoom_extractsResultAndMutatesSubState() {
        let counter = Stateful<Int, String> { n in
            let snapshot = "\(n)"
            n += 1
            return snapshot
        }
        let (result, final) = countLens.zoom(counter).runStateful(initial)
        #expect(result == "0")
        #expect(final.count == 1)
        #expect(final.address.street == "1st Ave")
    }

    @Test func zoom_voidResult_mutatesSubState() {
        let increment = Stateful<Int, Void> { $0 += 10 }
        let (_, final) = countLens.zoom(increment).runStateful(initial)
        #expect(final.count == 10)
        #expect(final.items == [1, 2, 3])
    }

    @Test func zoom_composedLenses_mutatesNestedSubState() {
        let streetUpper = Stateful<String, Void> { $0 = $0.uppercased() }
        let (_, final) = addressLens.compose(streetLens).zoom(streetUpper).runStateful(initial)
        #expect(final.address.street == "1ST AVE")
        #expect(final.count == 0)
    }
}

// MARK: - Prism.zoom

@Suite("Prism.zoom")
struct PrismZoomTests {
    private let homePrism = prism(\Route.homeValue, review: Route.home)

    @Test func zoom_hit_extractsResultAndUpdatesState() {
        let double = Stateful<Int, Int> { n in
            let old = n
            n *= 2
            return old
        }
        let (result, final) = homePrism.zoom(double).runStateful(.home(5))
        #expect(result == 5)
        guard case .home(let v) = final else { Issue.record("Expected .home"); return }
        #expect(v == 10)
    }

    @Test func zoom_miss_returnsNilAndLeavesStateUnchanged() {
        let double = Stateful<Int, Int> { n in n *= 2; return n }
        let (result, final) = homePrism.zoom(double).runStateful(.other)
        #expect(result == nil)
        guard case .other = final else { Issue.record("Expected .other"); return }
    }
}

// MARK: - AffineTraversal.zoom

@Suite("AffineTraversal.zoom")
struct AffineTraversalZoomTests {
    private let initial = AppState(count: 0, address: Address(street: "1st"), items: [10, 20, 30])

    @Test func zoom_hit_extractsResultAndMutatesElement() {
        let pop = Stateful<Int, Int> { n in
            let old = n
            n += 100
            return old
        }
        let (result, final) = [Int].ix(1).zoom(pop).runStateful([10, 20, 30])
        #expect(result == 20)
        #expect(final == [10, 120, 30])
    }

    @Test func zoom_miss_returnsNilAndLeavesStateUnchanged() {
        let pop = Stateful<Int, Int> { n in n += 100; return n }
        let (result, final) = [Int].ix(9).zoom(pop).runStateful([10, 20, 30])
        #expect(result == nil)
        #expect(final == [10, 20, 30])
    }

    @Test func zoom_dictionary_hit() {
        let increment = Stateful<Int, Void> { $0 += 1 }
        let (_, final) = [String: Int].ix(key: "a").zoom(increment).runStateful(["a": 5, "b": 2])
        #expect(final["a"] == 6)
        #expect(final["b"] == 2)
    }

    @Test func zoom_dictionary_miss_unchanged() {
        let increment = Stateful<Int, Void> { $0 += 1 }
        let final = [String: Int].ix(key: "z").zoom(increment).exec(["a": 5])
        #expect(final == ["a": 5])
    }
}
