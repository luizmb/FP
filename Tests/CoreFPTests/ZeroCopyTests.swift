// SPDX-License-Identifier: Apache-2.0
// swiftlint:disable discouraged_optional_collection
@testable import CoreFP
import Testing

// Zero-copy checks: a mutation is in place when the array buffer keeps its base address.
// `swift test` builds at -Onone, where nothing is optimised away, so these tests prove the
// ownership in the source (`consume` / `consuming`), not a lucky optimiser pass.

// MARK: - Fixtures

private func address(_ array: [Int]) -> UnsafeRawPointer? {
    array.withUnsafeBufferPointer { UnsafeRawPointer($0.baseAddress) }
}

private func bigArray() -> [Int] { Array(0 ..< 1_000) }

private enum Route {
    case home
    case list([Int])
}

private extension Route {
    var list: [Int]? {
        guard case let .list(values) = self else { return nil }
        return values
    }
}

private struct Wrapper {
    var values: [Int]
}

private struct Model: Mutable {
    var items: [Int]
    var route: Route
    var maybe: [Int]?
}

private let listPrism: Prism<Route, [Int]> = prism(preview: { $0.list }, review: Route.list)
private let wrapperIso: Iso<Wrapper, [Int]> = iso(get: { $0.values }, reverseGet: Wrapper.init)

/// Runs `mutate` through `run` and reports the buffer address seen before and after the write.
private func probe(_ run: ((inout [Int]) -> Void) -> Void) -> (before: UnsafeRawPointer?, after: UnsafeRawPointer?) {
    var before: UnsafeRawPointer?
    var after: UnsafeRawPointer?
    run { values in
        before = address(values)
        values[0] = 99
        after = address(values)
    }
    return (before, after)
}

// MARK: - Prism

@Suite("Zero-copy — Prism")
struct PrismZeroCopyTests {
    @Test func tryModifyMut_mutatesPayloadInPlace() {
        var route = Route.list(bigArray())
        let seen = probe { f in listPrism.tryModifyMut(&route, f) }
        #expect(seen.before == seen.after)
        #expect(route.list?.first == 99)
    }

    @Test func tryModifyMut_missLeavesWholeUntouched() {
        var route = Route.home
        var called = false
        // swiftlint:disable:next closure_ignoring_args
        listPrism.tryModifyMut(&route) { _ in called = true }
        #expect(!called)
        #expect(route.list == nil)
    }

    @Test func lift_mutatesPayloadInPlace() {
        var route = Route.list(bigArray())
        let before = route.list.flatMap(address)
        listPrism.lift(EndoMut { $0[0] = 99 })(&route)
        #expect(route.list.flatMap(address) == before)
        #expect(route.list?.first == 99)
    }

    @Test func over_throughElement_isInPlace() {
        var route = Route.list(bigArray())
        let before = route.list.flatMap(address)
        route = listPrism.compose([Int].ix(0)).over { $0 + 1 }(consume route)
        #expect(route.list.flatMap(address) == before)
        #expect(route.list?.first == 1)
    }
}

// MARK: - Iso

@Suite("Zero-copy — Iso")
struct IsoZeroCopyTests {
    @Test func lift_isInPlace() {
        var wrapper = Wrapper(values: bigArray())
        let before = address(wrapper.values)
        wrapperIso.lift(EndoMut { $0[0] = 99 })(&wrapper)
        #expect(address(wrapper.values) == before)
        #expect(wrapper.values.first == 99)
    }

    @Test func modifyMut_isInPlace() {
        var wrapper = Wrapper(values: bigArray())
        let seen = probe { f in wrapperIso.modifyMut(&wrapper, f) }
        #expect(seen.before == seen.after)
        #expect(wrapper.values.first == 99)
    }

    @Test func asLens_modifyMut_isInPlace() {
        var wrapper = Wrapper(values: bigArray())
        let seen = probe { f in wrapperIso.asLens.modifyMut(&wrapper, f) }
        #expect(seen.before == seen.after)
    }

    @Test func asPrism_tryModifyMut_isInPlace() {
        var wrapper = Wrapper(values: bigArray())
        let seen = probe { f in wrapperIso.asPrism.tryModifyMut(&wrapper, f) }
        #expect(seen.before == seen.after)
    }

    @Test func asAffineTraversal_tryModifyMut_isInPlace() {
        var wrapper = Wrapper(values: bigArray())
        let seen = probe { f in wrapperIso.asAffineTraversal.tryModifyMut(&wrapper, f) }
        #expect(seen.before == seen.after)
    }
}

// MARK: - Lens

@Suite("Zero-copy — Lens")
struct LensZeroCopyTests {
    private let firstItem = lens(\Model.items).compose([Int].ix(0))

    @Test func over_throughElement_isInPlace() {
        var model = Model(items: bigArray(), route: .home, maybe: nil)
        let before = address(model.items)
        model = firstItem.over { $0 + 1 }(consume model)
        #expect(address(model.items) == before)
        #expect(model.items.first == 1)
    }

    @Test func set_throughElement_isInPlace() {
        var model = Model(items: bigArray(), route: .home, maybe: nil)
        let before = address(model.items)
        model = firstItem.set(consume model, 42)
        #expect(address(model.items) == before)
        #expect(model.items.first == 42)
    }

    @Test func lensPrismElementSet_isInPlace() {
        var model = Model(items: [], route: .list(bigArray()), maybe: nil)
        let before = model.route.list.flatMap(address)
        model = lens(\Model.route).compose(listPrism).compose([Int].ix(0)).set(consume model, 7)
        #expect(model.route.list.flatMap(address) == before)
        #expect(model.route.list?.first == 7)
    }

    @Test func liveOriginal_isCopiedNotShared() {
        let original = Model(items: bigArray(), route: .home, maybe: nil)
        let updated = firstItem.set(original, 42)
        #expect(address(updated.items) != address(original.items))
        #expect(original.items.first == 0)
        #expect(updated.items.first == 42)
    }
}

// MARK: - AffineTraversal and Traversal

@Suite("Zero-copy — Traversals")
struct TraversalZeroCopyTests {
    @Test func ixSet_isInPlace() {
        var values = bigArray()
        let before = address(values)
        values = [Int].ix(3).set(consume values, 42)
        #expect(address(values) == before)
        #expect(values[3] == 42)
    }

    @Test func optionalKeyPathTraversal_tryModifyMut_isInPlace() {
        var model = Model(items: [], route: .home, maybe: bigArray())
        let seen = probe { f in affineTraversal(\Model.maybe).tryModifyMut(&model, f) }
        #expect(seen.before == seen.after)
        #expect(model.maybe?.first == 99)
    }

    @Test func dictionaryIx_tryModifyMut_isInPlace() {
        var table = ["a": bigArray()]
        let seen = probe { f in [String: [Int]].ix(key: "a").tryModifyMut(&table, f) }
        #expect(seen.before == seen.after)
        #expect(table["a"]?.first == 99)
    }

    @Test func eachOver_isInPlace() {
        var values = bigArray()
        let before = address(values)
        values = [Int].each.over { $0 + 1 }(consume values)
        #expect(address(values) == before)
        #expect(values[0] == 1)
    }

    @Test func eachSetAll_isInPlace() {
        var values = bigArray()
        let before = address(values)
        values = [Int].each.setAll(consume values, 0)
        #expect(address(values) == before)
        #expect(values.allSatisfy { $0 == 0 })
    }

    @Test func isoTraversal_modifyMut_isInPlace() {
        var wrapper = Wrapper(values: bigArray())
        let seen = probe { f in wrapperIso.traversal.modifyMut(&wrapper) { f(&$0) } }
        #expect(seen.before == seen.after)
        #expect(wrapper.values.first == 99)
    }

    @Test func eachModifyMut_writesTheBufferInPlace() {
        var values = bigArray()
        let before = address(values)
        [Int].each.modifyMut(&values) { $0 += 1 }
        #expect(address(values) == before)
        #expect(values[999] == 1_000)
    }

    @Test func eachModifyMut_onArraySliceWritesTheRightElements() {
        var slice = bigArray()[10 ..< 20]
        [Int].SubSequence.each.modifyMut(&slice) { $0 = -$0 }
        #expect(slice.startIndex == 10)
        #expect(Array(slice) == (10 ..< 20).map { -$0 })
    }

    @Test func eachModifyMut_onSharedArrayCopiesAndLeavesTheOriginal() {
        let original = bigArray()
        var values = original
        [Int].each.modifyMut(&values) { $0 += 1 }
        #expect(address(values) != address(original))
        #expect(original[0] == 0)
        #expect(values[0] == 1)
    }

    @Test func eachIndexedOver_isInPlace() {
        var values = bigArray()
        let before = address(values)
        values = [Int].eachIndexed.over { index, _ in index * 2 }(consume values)
        #expect(address(values) == before)
        #expect(values[3] == 6)
    }
}

// MARK: - Mutable

@Suite("Zero-copy — Mutable")
struct MutableZeroCopyTests {
    @Test func mutate_isInPlace() {
        var model = Model(items: bigArray(), route: .home, maybe: nil)
        let before = address(model.items)
        model = (consume model).mutate { $0.items[0] = 99 }
        #expect(address(model.items) == before)
        #expect(model.items.first == 99)
    }
}

// swiftlint:enable discouraged_optional_collection
