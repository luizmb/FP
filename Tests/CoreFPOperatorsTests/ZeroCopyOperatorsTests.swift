// SPDX-License-Identifier: Apache-2.0
// swiftlint:disable discouraged_optional_collection
import CoreFP
@testable import CoreFPOperators
import Testing

// Operator forms of the zero-copy checks in CoreFPTests/ZeroCopyTests.swift: a composed
// optic built with `>>>` keeps the array buffer's base address when it writes through it.

private func address(_ array: [Int]) -> UnsafeRawPointer? {
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

private struct Model {
    var items: [Int]
    var route: Route
}

private let listPrism: Prism<Route, [Int]> = prism(preview: { $0.list }, review: Route.list)

@Suite("Zero-copy — >>> composition")
struct ZeroCopyOperatorsTests {
    @Test func lensIxOver_isInPlace() {
        var model = Model(items: Array(0 ..< 1_000), route: .home)
        let before = address(model.items)
        model = (^\Model.items >>> [Int].ix(0)).over { $0 + 1 }(consume model)
        #expect(address(model.items) == before)
        #expect(model.items.first == 1)
    }

    @Test func lensPrismIxSet_isInPlace() {
        var model = Model(items: [], route: .list(Array(0 ..< 1_000)))
        let before = model.route.list.flatMap(address)
        model = (^\Model.route >>> listPrism >>> [Int].ix(0)).set(consume model, 7)
        #expect(model.route.list.flatMap(address) == before)
        #expect(model.route.list?.first == 7)
    }

    @Test func lensPrismLift_isInPlace() {
        var model = Model(items: [], route: .list(Array(0 ..< 1_000)))
        let before = model.route.list.flatMap(address)
        (^\Model.route >>> listPrism).lift(EndoMut { $0[0] = 99 })(&model)
        #expect(model.route.list.flatMap(address) == before)
        #expect(model.route.list?.first == 99)
    }
}

// swiftlint:enable discouraged_optional_collection
