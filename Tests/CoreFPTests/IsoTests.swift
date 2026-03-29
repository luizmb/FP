@testable import CoreFP
import Testing

// MARK: - Fixtures

private let addOne = iso(get: { $0 + 1 }, reverseGet: { $0 - 1 })   // Iso<Int, Int>
private let timesTwo = iso(get: { $0 * 2 }, reverseGet: { $0 / 2 })   // Iso<Int, Int>
private let swap     = iso(get: { (a: Int, b: Int) in (b, a) },
                           reverseGet: { (a: Int, b: Int) in (b, a) }) // Iso<(Int,Int),(Int,Int)>

private struct Point: Equatable { var x: Double; var y: Double }
private let mirrorX = iso(get: { Point(x: -$0.x, y: $0.y) },
                          reverseGet: { Point(x: -$0.x, y: $0.y) })   // Iso<Point, Point>

@Suite struct IsoTests {
    // MARK: - Round-trip laws

    @Test func roundTripForward() {
        let s = 5
        #expect(addOne.reverseGet(addOne.get(s)) == s)
    }

    @Test func roundTripBackward() {
        let a = 6
        #expect(addOne.get(addOne.reverseGet(a)) == a)
    }

    // MARK: - get / reverseGet

    @Test func get() {
        #expect(addOne.get(5) == 6)
        #expect(timesTwo.get(3) == 6)
    }

    @Test func reverseGet() {
        #expect(addOne.reverseGet(6) == 5)
        #expect(timesTwo.reverseGet(6) == 3)
    }

    // MARK: - reverse

    @Test func reverse() {
        let rev = addOne.reverse    // Iso<Int, Int> with get = -1, reverseGet = +1
        #expect(rev.get(6) == 5)
        #expect(rev.reverseGet(5) == 6)
    }

    @Test func reverseRoundTrip() {
        let rev = addOne.reverse
        let s = 5
        #expect(rev.reverseGet(rev.get(s)) == s)
    }

    // MARK: - over

    @Test func over() {
        // addOne.over doubles: get (+1), transform (*10), reverseGet (-1)
        let transform = addOne.over { $0 * 10 }
        #expect(transform(3) == 39)  // (3+1)*10 - 1 = 40 - 1 = 39
    }

    @Test func overIdentity() {
        let transform = addOne.over { $0 }
        #expect(transform(7) == 7)   // round-trip with identity is a no-op
    }

    // MARK: - asLens

    @Test func asLens_get() {
        let l = addOne.asLens
        #expect(l.get(5) == 6)
    }

    @Test func asLens_set() {
        let l = addOne.asLens
        // set ignores the original S and uses reverseGet
        #expect(l.set(0, 6) == 5)
        #expect(l.set(99, 6) == 5)
    }

    @Test func asLens_over() {
        let l = addOne.asLens
        #expect(l.over { $0 * 10 }(3) == 39)
    }

    // MARK: - asPrism

    @Test func asPrism_preview_alwaysSucceeds() {
        let p = addOne.asPrism
        #expect(p.preview(5) == .some(6))
        #expect(p.preview(0) == .some(1))
    }

    @Test func asPrism_review() {
        let p = addOne.asPrism
        #expect(p.review(6) == 5)
    }

    // MARK: - asAffineTraversal

    @Test func asAffineTraversal_preview() {
        let at = addOne.asAffineTraversal
        #expect(at.preview(5) == .some(6))
    }

    @Test func asAffineTraversal_set() {
        let at = addOne.asAffineTraversal
        #expect(at.set(0, 6) == 5)
    }

    // MARK: - Semigroup (Iso<A,A>)

    @Test func semigroup_combine() {
        let combined = Iso<Int, Int>.combine(addOne, timesTwo)
        // addOne.get(5) = 6, timesTwo.get(6) = 12
        #expect(combined.get(5) == 12)
        // timesTwo.reverseGet(12) = 6, addOne.reverseGet(6) = 5
        #expect(combined.reverseGet(12) == 5)
    }

    @Test func semigroup_combine_via_mconcat() {
        let transform = mconcat([addOne, timesTwo, addOne])
        // 5 +1=6, *2=12, +1=13
        #expect(transform.get(5) == 13)
        // 13 -1=12, /2=6, -1=5
        #expect(transform.reverseGet(13) == 5)
    }

    // MARK: - Monoid (Iso<A,A>)

    @Test func monoid_identity() {
        let id = Iso<Int, Int>.identity
        #expect(id.get(42) == 42)
        #expect(id.reverseGet(42) == 42)
    }

    @Test func monoid_identity_is_neutral_left() {
        let combined = Iso<Int, Int>.combine(.identity, addOne)
        #expect(combined.get(5) == addOne.get(5))
    }

    @Test func monoid_identity_is_neutral_right() {
        let combined = Iso<Int, Int>.combine(addOne, .identity)
        #expect(combined.get(5) == addOne.get(5))
    }

    // MARK: - Tuple swap iso

    @Test func swapIso_roundTrip() {
        let pair = (1, 2)
        #expect(swap.reverseGet(swap.get(pair)) == pair)
        #expect(swap.get(pair) == (2, 1))
    }

    // MARK: - iso() constructor

    @Test func isoConstructor() {
        let i = iso(get: { $0 + 10 }, reverseGet: { $0 - 10 })
        #expect(i.get(5) == 15)
        #expect(i.reverseGet(15) == 5)
    }
}

// MARK: - Binding tests (Apple platforms only)

#if canImport(SwiftUI)
import SwiftUI

private struct User: Equatable {
    var name: String
    var age: Int
}

private enum Shape: Equatable {
    case circle(Double)
    case rectangle(Double, Double)
}

private func mutableBinding<V>(_ initial: V) -> (binding: Binding<V>, read: () -> V) {
    var storage = initial
    return (
        Binding(get: { storage }, set: { storage = $0 }),
        { storage }
    )
}

@Suite struct BindingOpticsTests {
    // MARK: - Lens

    @Test func bindingLens_get() {
        let nameLens: Lens<User, String> = lens(\.name)
        let (binding, _) = mutableBinding(User(name: "Alice", age: 30))
        #expect(binding[optic: nameLens].wrappedValue == "Alice")
    }

    @Test func bindingLens_set() {
        let nameLens: Lens<User, String> = lens(\.name)
        let (binding, read) = mutableBinding(User(name: "Alice", age: 30))
        binding[optic: nameLens].wrappedValue = "Bob"
        #expect(read().name == "Bob")
        #expect(read().age == 30)   // other fields untouched
    }

    // MARK: - Iso

    @Test func bindingIso_get() {
        let addOne = iso(get: { $0 + 1 }, reverseGet: { $0 - 1 })
        let (binding, _) = mutableBinding(5)
        #expect(binding[optic: addOne].wrappedValue == 6)
    }

    @Test func bindingIso_set() {
        let addOne = iso(get: { $0 + 1 }, reverseGet: { $0 - 1 })
        let (binding, read) = mutableBinding(5)
        binding[optic: addOne].wrappedValue = 10
        #expect(read() == 9)   // reverseGet(10) = 9
    }

    // MARK: - Prism

    @Test func bindingPrism_activeCase_isNonNil() {
        let circlePrism: Prism<Shape, Double> = prism(
            preview: { if case .circle(let r) = $0 { return r } else { return nil } },
            review: Shape.circle
        )
        let (binding, _) = mutableBinding(Shape.circle(5.0))
        #expect(binding[optic: circlePrism] != nil)
        #expect(binding[optic: circlePrism]?.wrappedValue == 5.0)
    }

    @Test func bindingPrism_inactiveCase_isNil() {
        let circlePrism: Prism<Shape, Double> = prism(
            preview: { if case .circle(let r) = $0 { return r } else { return nil } },
            review: Shape.circle
        )
        let (binding, _) = mutableBinding(Shape.rectangle(3, 4))
        #expect(binding[optic: circlePrism] == nil)
    }

    @Test func bindingPrism_set() {
        let circlePrism: Prism<Shape, Double> = prism(
            preview: { if case .circle(let r) = $0 { return r } else { return nil } },
            review: Shape.circle
        )
        let (binding, read) = mutableBinding(Shape.circle(5.0))
        binding[optic: circlePrism]?.wrappedValue = 10.0
        #expect(read() == .circle(10.0))
    }

    // MARK: - AffineTraversal

    @Test func bindingAffineTraversal_present() {
        let nameAT: AffineTraversal<User?, String> = AffineTraversal(
            preview: { $0?.name },
            set: { s, v in s.map { User(name: v, age: $0.age) } }
        )
        let (binding, _) = mutableBinding(Optional(User(name: "Alice", age: 30)))
        #expect(binding[optic: nameAT]?.wrappedValue == "Alice")
    }

    @Test func bindingAffineTraversal_absent() {
        let nameAT: AffineTraversal<User?, String> = AffineTraversal(
            preview: { $0?.name },
            set: { s, v in s.map { User(name: v, age: $0.age) } }
        )
        let (binding, _) = mutableBinding(Optional<User>.none)
        #expect(binding[optic: nameAT] == nil)
    }
}
#endif
