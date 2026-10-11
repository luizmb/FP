// SPDX-License-Identifier: Apache-2.0
// swiftlint:disable discouraged_optional_collection
import CoreFP
@testable import DataStructure
import Testing

// Zero-copy checks: a mutation is in place when the array buffer keeps its base address.
// `swift test` builds at -Onone, so these tests prove the ownership in the source.

// MARK: - Fixtures

private func address<T>(_ array: [T]) -> UnsafeRawPointer? {
    array.withUnsafeBufferPointer { UnsafeRawPointer($0.baseAddress) }
}

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

private struct Item: Identifiable, Sendable {
    let id: Int
    var name: String
}

// MARK: - NonEmpty

@Suite("Zero-copy — NonEmpty")
struct NonEmptyZeroCopyTests {
    private func roomyList() -> NonEmpty<Int> {
        var rest: [Int] = []
        rest.reserveCapacity(64)
        rest.append(contentsOf: [2, 3])
        return NonEmpty(head: 1, tail: rest)
    }

    @Test func append_handedOver_isInPlace() {
        var list = roomyList()
        let before = address(list.tail)
        list = (consume list).append(4)
        #expect(address(list.tail) == before)
        #expect(list.toArray == [1, 2, 3, 4])
    }

    @Test func appendContentsOf_handedOver_isInPlace() {
        var list = roomyList()
        let before = address(list.tail)
        list = (consume list).append(contentsOf: [4, 5])
        #expect(address(list.tail) == before)
        #expect(list.toArray == [1, 2, 3, 4, 5])
    }

    @Test func append_liveOriginal_isUntouched() {
        let original = roomyList()
        let appended = original.append(4)
        #expect(original.toArray == [1, 2, 3])
        #expect(appended.toArray == [1, 2, 3, 4])
    }
}

// MARK: - Stateful zoom

@Suite("Zero-copy — Prism.zoom")
struct PrismZoomZeroCopyTests {
    @Test func zoom_mutatesPayloadInPlace() {
        let listPrism: Prism<Route, [Int]> = prism(preview: { $0.list }, review: Route.list)
        var route = Route.list(Array(0 ..< 1_000))
        let before = route.list.flatMap(address)
        let zoomed = listPrism.zoom(Stateful<[Int], Int> { values in
            values[0] = 99
            return values.count
        })
        let result = zoomed.run(&route)
        #expect(result == 1_000)
        #expect(route.list.flatMap(address) == before)
        #expect(route.list?.first == 99)
    }
}

// MARK: - IdentifiedArray

@Suite("Zero-copy — IdentifiedArray")
struct IdentifiedArrayZeroCopyTests {
    private func items() -> IdentifiedArrayOf<Item> {
        IdentifiedArray((0 ..< 100).map { Item(id: $0, name: "item \($0)") })
    }

    @Test func ixIdSet_handedOver_isInPlace() {
        var all = items()
        let before = address(all.storage)
        all = IdentifiedArray.ix(id: 3).set(consume all, Item(id: 3, name: "renamed"))
        #expect(address(all.storage) == before)
        #expect(all[id: 3]?.name == "renamed")
    }

    @Test func ixPositionSet_handedOver_isInPlace() {
        var all = items()
        let before = address(all.storage)
        all = IdentifiedArray.ix(5).set(consume all, Item(id: 5, name: "renamed"))
        #expect(address(all.storage) == before)
        #expect(all[id: 5]?.name == "renamed")
    }
}

// swiftlint:enable discouraged_optional_collection
