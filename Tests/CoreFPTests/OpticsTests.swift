@testable import CoreFP
import Testing

// MARK: - Fixtures

private struct Address {
    var street: String
}

private struct Person {
    var age: Int
    let name: String
    var address: Address
}

private enum Shape {
    case circle(Double)
    case rectangle(Double, Double)
}

private extension Shape {
    var circleRadius: Double? {
        guard case .circle(let r) = self else { return nil }
        return r
    }
}

// MARK: - Lenses

@Suite("Lens")
struct LensTests {
    // MARK: WritableKeyPath lift

    @Test func lensFromWritableKeyPath_get() {
        let ageLens = lens(\Person.age)
        let person = Person(age: 30, name: "Alice", address: Address(street: "1st Ave"))
        #expect(ageLens.get(person) == 30)
    }

    @Test func lensFromWritableKeyPath_set() {
        let ageLens = lens(\Person.age)
        let person = Person(age: 30, name: "Alice", address: Address(street: "1st Ave"))
        let updated = ageLens.set(person, 31)
        #expect(updated.age == 31)
        #expect(updated.name == "Alice")
    }

    @Test func lensFromWritableKeyPath_over() {
        let ageLens = lens(\Person.age)
        let person = Person(age: 30, name: "Alice", address: Address(street: "1st Ave"))
        let updated = ageLens.over({ $0 + 1 })(person)
        #expect(updated.age == 31)
    }

    // MARK: KeyPath + manual setter lift

    @Test func lensFromKeyPath_get() {
        let nameLens = lens(\.name) { (p: Person, n) in Person(age: p.age, name: n, address: p.address) }
        let person = Person(age: 30, name: "Alice", address: Address(street: "1st Ave"))
        #expect(nameLens.get(person) == "Alice")
    }

    @Test func lensFromKeyPath_set() {
        let nameLens = lens(\.name) { (p: Person, n) in Person(age: p.age, name: n, address: p.address) }
        let person = Person(age: 30, name: "Alice", address: Address(street: "1st Ave"))
        let updated = nameLens.set(person, "Bob")
        #expect(updated.name == "Bob")
        #expect(updated.age == 30)
    }

    // MARK: Lens laws

    @Test("get-set: setting what you got leaves the structure unchanged")
    func law_getSet() {
        let ageLens = lens(\Person.age)
        let person = Person(age: 30, name: "Alice", address: Address(street: "1st Ave"))
        #expect(ageLens.set(person, ageLens.get(person)).age == person.age)
    }

    @Test("set-get: getting after setting returns the new value")
    func law_setGet() {
        let ageLens = lens(\Person.age)
        let person = Person(age: 30, name: "Alice", address: Address(street: "1st Ave"))
        #expect(ageLens.get(ageLens.set(person, 99)) == 99)
    }

    @Test("set-set: setting twice is the same as setting once with the last value")
    func law_setSet() {
        let ageLens = lens(\Person.age)
        let person = Person(age: 30, name: "Alice", address: Address(street: "1st Ave"))
        let once = ageLens.set(ageLens.set(person, 40), 99)
        let twice = ageLens.set(person, 99)
        #expect(once.age == twice.age)
    }

    // MARK: lift

    @Test func lift_writableKeyPath_mutatesTargetField() {
        var person = Person(age: 30, name: "Alice", address: Address(street: "1st Ave"))
        lens(\Person.age).lift(EndoMut { $0 += 1 })(&person)
        #expect(person.age == 31)
        #expect(person.name == "Alice")
    }

    @Test func lift_computedSetter_mutatesTargetField() {
        let nameLens = lens(\.name) { (p: Person, n) in Person(age: p.age, name: n, address: p.address) }
        var person = Person(age: 30, name: "Alice", address: Address(street: "1st Ave"))
        nameLens.lift(EndoMut { $0 = $0.uppercased() })(&person)
        #expect(person.name == "ALICE")
        #expect(person.age == 30)
    }
}

// MARK: - Prisms

@Suite("Prism")
struct PrismTests {
    private let circlePrism = prism(\Shape.circleRadius, review: Shape.circle)

    @Test func preview_hit() {
        #expect(circlePrism.preview(.circle(3.0)) == 3.0)
    }

    @Test func preview_miss() {
        #expect(circlePrism.preview(.rectangle(2.0, 4.0)) == nil)
    }

    @Test func review() {
        guard case .circle(let r) = circlePrism.review(5.0) else {
            Issue.record("Expected .circle")
            return
        }
        #expect(r == 5.0)
    }

    @Test func over_hit() {
        let doubled = circlePrism.over({ $0 * 2 })(.circle(3.0))
        guard case .circle(let r) = doubled else {
            Issue.record("Expected .circle")
            return
        }
        #expect(r == 6.0)
    }

    @Test func over_miss() {
        let rect = Shape.rectangle(2.0, 4.0)
        let result = circlePrism.over({ $0 * 2 })(rect)
        guard case .rectangle(let w, let h) = result else {
            Issue.record("Expected .rectangle")
            return
        }
        #expect(w == 2.0)
        #expect(h == 4.0)
    }

    // MARK: lift

    @Test func lift_hit_mutatesFocusedValue() {
        var shape = Shape.circle(3.0)
        circlePrism.lift(EndoMut { $0 *= 2 })(&shape)
        guard case .circle(let r) = shape else { Issue.record("Expected .circle"); return }
        #expect(r == 6.0)
    }

    @Test func lift_miss_isNoOp() {
        var shape = Shape.rectangle(1.0, 2.0)
        circlePrism.lift(EndoMut { $0 *= 2 })(&shape)
        guard case .rectangle(let w, let h) = shape else { Issue.record("Expected .rectangle"); return }
        #expect(w == 1.0)
        #expect(h == 2.0)
    }
}

// MARK: - AffineTraversal

@Suite("AffineTraversal")
struct AffineTraversalTests {
    private let streetAT = AffineTraversal<Person, String>(
        preview: { $0.address.street },
        set: { p, s in
            var copy = p
            copy.address.street = s
            return copy
        }
    )

    @Test func preview() {
        let person = Person(age: 30, name: "Alice", address: Address(street: "1st Ave"))
        #expect(streetAT.preview(person) == "1st Ave")
    }

    @Test func set() {
        let person = Person(age: 30, name: "Alice", address: Address(street: "1st Ave"))
        let updated = streetAT.set(person, "2nd Ave")
        #expect(updated.address.street == "2nd Ave")
        #expect(updated.name == "Alice")
    }

    @Test func over() {
        let person = Person(age: 30, name: "Alice", address: Address(street: "1st Ave"))
        let updated = streetAT.over({ $0.uppercased() })(person)
        #expect(updated.address.street == "1ST AVE")
    }

    // MARK: lift

    @Test func lift_hit_mutatesFocusedValue() {
        var person = Person(age: 30, name: "Alice", address: Address(street: "1st Ave"))
        streetAT.lift(EndoMut { $0 = $0.uppercased() })(&person)
        #expect(person.address.street == "1ST AVE")
        #expect(person.name == "Alice")
    }
}

// MARK: - compose (no operators)

@Suite("compose (named function, no operators)")
struct ComposeTests {
    private let addressLens = lens(\Person.address)
    private let streetLens  = lens(\Address.street)
    private let circlePrism = prism(\Shape.circleRadius, review: Shape.circle)

    @Test func lensComposeLens_get() {
        let personStreet = addressLens.compose(streetLens)
        let person = Person(age: 30, name: "Alice", address: Address(street: "1st Ave"))
        #expect(personStreet.get(person) == "1st Ave")
    }

    @Test func lensComposeLens_set() {
        let personStreet = addressLens.compose(streetLens)
        let person = Person(age: 30, name: "Alice", address: Address(street: "1st Ave"))
        #expect(personStreet.set(person, "2nd Ave").address.street == "2nd Ave")
    }

    @Test func lensComposeLens_lift() {
        let personStreet = addressLens.compose(streetLens)
        var person = Person(age: 30, name: "Alice", address: Address(street: "1st Ave"))
        personStreet.lift(EndoMut { $0 = $0.uppercased() })(&person)
        #expect(person.address.street == "1ST AVE")
        #expect(person.age == 30)
    }

    @Test func lensComposePrism_preview_hit() {
        struct World { var shape: Shape }
        let shapeLens = lens(\World.shape)
        let circleInWorld = shapeLens.compose(circlePrism)
        #expect(circleInWorld.preview(World(shape: .circle(3.0))) == 3.0)
    }

    @Test func lensComposePrism_preview_miss() {
        struct World { var shape: Shape }
        let shapeLens = lens(\World.shape)
        let circleInWorld = shapeLens.compose(circlePrism)
        #expect(circleInWorld.preview(World(shape: .rectangle(1.0, 2.0))) == nil)
    }

    @Test func lensComposeAffineTraversal_lift_mutatesElement() {
        struct AppState { var items: [Int] }
        let itemsLens = lens(\AppState.items)
        var state = AppState(items: [10, 20, 30])
        itemsLens.compose([Int].ix(1)).lift(EndoMut { $0 += 5 })(&state)
        #expect(state.items == [10, 25, 30])
    }
}
