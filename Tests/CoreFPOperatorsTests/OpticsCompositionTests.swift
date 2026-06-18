// SPDX-License-Identifier: Apache-2.0
import CoreFP
@testable import CoreFPOperators
import Testing

// MARK: - Fixtures

private struct Address {
    var street: String
    let city: String
}

private struct Person {
    var age: Int
    let name: String
    var address: Address
}

private enum Shape {
    case circle(Double)
    case rectangle(Double, Double)

    var circleRadius: Double? {
        guard case .circle(let r) = self else { return nil }
        return r
    }
}

private let ageLens     = lens(\Person.age)
private let addressLens = lens(\Person.address)
private let streetLens  = lens(\Address.street)
private let cityLens    = lens(\Address.city) { (a: Address, c) in Address(street: a.street, city: c) }
private let circlePrism = prism(\Shape.circleRadius, review: Shape.circle)
private let alice       = Person(age: 30, name: "Alice", address: Address(street: "1st Ave", city: "NY"))

// MARK: - ^ operator

@Suite("^ operator")
struct CaretOperatorTests {
    @Test func writableKeyPath_producesLens() {
        let l: Lens<Person, Int> = ^\Person.age
        #expect(l.get(alice) == 30)
        #expect(l.set(alice, 99).age == 99)
    }

    @Test func keyPath_producesPartialBuilder() {
        let nameLens: Lens<Person, String> = (^\Person.name) { Person(age: $0.age, name: $1, address: $0.address) }
        #expect(nameLens.get(alice) == "Alice")
        #expect(nameLens.set(alice, "Bob").name == "Bob")
    }
}

// MARK: - Lens >>> Lens

@Suite("Lens >>> Lens")
struct LensLensCompositionTests {
    private var personStreetLens: Lens<Person, String> { addressLens >>> streetLens }

    @Test func get() {
        #expect(personStreetLens.get(alice) == "1st Ave")
    }

    @Test func set() {
        let updated = personStreetLens.set(alice, "2nd Ave")
        #expect(updated.address.street == "2nd Ave")
        #expect(updated.age == 30)
    }

    @Test func over() {
        let updated = personStreetLens.over({ $0.uppercased() })(alice)
        #expect(updated.address.street == "1ST AVE")
    }
}

// MARK: - Lens >>> Prism

@Suite("Lens >>> Prism")
struct LensPrismCompositionTests {
    private struct World {
        var shape: Shape
    }

    private var shapeLens: Lens<World, Shape> { lens(\World.shape) }
    private var circleInWorld: AffineTraversal<World, Double> { shapeLens >>> circlePrism }

    @Test func preview_hit() {
        #expect(circleInWorld.preview(World(shape: .circle(3.0))) == 3.0)
    }

    @Test func preview_miss() {
        #expect(circleInWorld.preview(World(shape: .rectangle(2.0, 4.0))) == nil)
    }

    @Test func set_hit() {
        let updated = circleInWorld.set(World(shape: .circle(3.0)), 9.0)
        guard case .circle(let r) = updated.shape else {
            Issue.record("Expected .circle")
            return
        }
        #expect(r == 9.0)
    }

    @Test func over_miss_leavesSUnchanged() {
        let w = World(shape: .rectangle(1.0, 2.0))
        let updated = circleInWorld.over({ $0 * 2 })(w)
        guard case .rectangle(let a, let b) = updated.shape else {
            Issue.record("Expected .rectangle")
            return
        }
        #expect(a == 1.0)
        #expect(b == 2.0)
    }
}

// MARK: - Prism >>> Lens

@Suite("Prism >>> Lens")
struct PrismLensCompositionTests {
    private struct Circle {
        var radius: Double
        var lineWidth: Double
    }

    private enum Drawing {
        case circle(Circle)
        case other

        var circle: Circle? {
            guard case .circle(let c) = self else { return nil }
            return c
        }
    }

    private var circleStructPrism: Prism<Drawing, Circle> { prism(\Drawing.circle, review: Drawing.circle) }
    private var radiusLens: Lens<Circle, Double> { lens(\Circle.radius) }
    private var drawingRadius: AffineTraversal<Drawing, Double> { circleStructPrism >>> radiusLens }

    @Test func preview_hit() {
        #expect(drawingRadius.preview(.circle(Circle(radius: 5.0, lineWidth: 1.0))) == 5.0)
    }

    @Test func preview_miss() {
        #expect(drawingRadius.preview(.other) == nil)
    }

    @Test func over_hit() {
        let updated = drawingRadius.over({ $0 + 1 })(.circle(Circle(radius: 3.0, lineWidth: 1.0)))
        guard case .circle(let c) = updated else {
            Issue.record("Expected .circle")
            return
        }
        #expect(c.radius == 4.0)
        #expect(c.lineWidth == 1.0)
    }

    @Test func over_miss_unchanged() {
        let result = drawingRadius.over({ $0 * 99 })(.other)
        guard case .other = result else {
            Issue.record("Expected .other")
            return
        }
    }
}

// MARK: - Prism >>> Prism

@Suite("Prism >>> Prism")
struct PrismPrismCompositionTests {
    private enum Outer {
        case inner(Shape)
        case other

        var inner: Shape? {
            guard case .inner(let s) = self else { return nil }
            return s
        }
    }

    private var innerPrism: Prism<Outer, Shape> { prism(\Outer.inner, review: Outer.inner) }
    private var deepCircle: Prism<Outer, Double> { innerPrism >>> circlePrism }

    @Test func preview_deepHit() {
        #expect(deepCircle.preview(.inner(.circle(7.0))) == 7.0)
    }

    @Test func preview_innerMiss() {
        #expect(deepCircle.preview(.other) == nil)
    }

    @Test func preview_outerMiss() {
        #expect(deepCircle.preview(.inner(.rectangle(1.0, 2.0))) == nil)
    }

    @Test func review() {
        let result = deepCircle.review(4.0)
        guard case .inner(let shape) = result, case .circle(let r) = shape else {
            Issue.record("Expected .inner(.circle)")
            return
        }
        #expect(r == 4.0)
    }
}

// MARK: - lift through compositions

@Suite("lift through composed optics")
struct LiftCompositionTests {
    private struct World {
        var shape: Shape
    }

    private var shapeLens: Lens<World, Shape> { lens(\World.shape) }

    @Test func lensLens_lift_mutatesNestedField() {
        var person = alice
        (addressLens >>> streetLens).lift(EndoMut { $0 = $0.uppercased() })(&person)
        #expect(person.address.street == "1ST AVE")
        #expect(person.age == 30)
    }

    @Test func lensPrism_lift_hit_mutatesFocus() {
        var world = World(shape: .circle(3.0))
        (shapeLens >>> circlePrism).lift(EndoMut { $0 *= 2 })(&world)
        guard case .circle(let r) = world.shape else { Issue.record("Expected .circle"); return }
        #expect(r == 6.0)
    }

    @Test func lensPrism_lift_miss_isNoOp() {
        var world = World(shape: .rectangle(1.0, 2.0))
        (shapeLens >>> circlePrism).lift(EndoMut { $0 *= 2 })(&world)
        guard case .rectangle(let w, let h) = world.shape else { Issue.record("Expected .rectangle"); return }
        #expect(w == 1.0)
        #expect(h == 2.0)
    }

    @Test func lensAffineTraversal_lift_mutatesCollectionElement() {
        struct AppState { var items: [Int] }
        let itemsLens = lens(\AppState.items)
        var state = AppState(items: [10, 20, 30])
        (itemsLens >>> [Int].ix(1)).lift(EndoMut { $0 += 5 })(&state)
        #expect(state.items == [10, 25, 30])
    }

    @Test func lensAffineTraversal_lift_outOfBounds_isNoOp() {
        struct AppState { var items: [Int] }
        let itemsLens = lens(\AppState.items)
        var state = AppState(items: [10, 20, 30])
        (itemsLens >>> [Int].ix(9)).lift(EndoMut { $0 += 5 })(&state)
        #expect(state.items == [10, 20, 30])
    }
}

// MARK: - Three-level chain: Lens >>> Lens >>> Prism

@Suite("Lens >>> Lens >>> Prism (three levels)")
struct ThreeLevelCompositionTests {
    private struct Container {
        var person: Person
        var shape: Shape
    }

    private var shapeLens: Lens<Container, Shape> { lens(\Container.shape) }
    private var containerCircle: AffineTraversal<Container, Double> { shapeLens >>> circlePrism }

    @Test func over_hit() {
        let c = Container(person: alice, shape: .circle(2.0))
        let updated = containerCircle.over({ $0 * 3 })(c)
        guard case .circle(let r) = updated.shape else {
            Issue.record("Expected .circle")
            return
        }
        #expect(r == 6.0)
    }

    @Test func over_miss_personUnchanged() {
        let c = Container(person: alice, shape: .rectangle(1.0, 2.0))
        let updated = containerCircle.over({ $0 * 3 })(c)
        #expect(updated.person.age == alice.age)
    }
}
