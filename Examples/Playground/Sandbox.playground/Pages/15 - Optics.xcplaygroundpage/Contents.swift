import FP

// ============================================================
// OPTICS: Lens, Prism, Iso, AffineTraversal
//
// Composable focusers for immutable data structures.
//   Lens<S, A>          — always-present field
//   Prism<S, A>         — optional case (enum variant)
//   Iso<S, A>           — lossless bidirectional conversion
//   AffineTraversal<S,A>— optional field with a setter
//
// All compose via >>> (forward) and <<< (backward).
// ============================================================

// MARK: - Lens

struct Person { var name: String; var age: Int }

func lens() {
    let nameLens: Lens<Person, String> = lens(\.name)
    let ageLens: Lens<Person, Int> = lens(\.age)

    let alice = Person(name: "Alice", age: 30)

    // get
    nameLens.get(alice) // "Alice"
    ageLens.get(alice) // 30

    // set
    nameLens.set(alice, "Bob") // Person(name: "Bob", age: 30)
    ageLens.set(alice, 31) // Person(name: "Alice", age: 31)

    // over — transform the focused value
    nameLens.over { $0.uppercased() }(alice) // Person(name: "ALICE", age: 30)
    ageLens.over { $0 + 1 }(alice) // Person(name: "Alice", age: 31)
}

// learn(lens)

func lensManualSet() {
    // For let properties or computed values — provide setter explicitly
    struct Point { let x: Double; let y: Double }

    let xLens = lens(\.x) { p, newX in Point(x: newX, y: p.y) }
    let p = Point(x: 1.0, y: 2.0)

    xLens.get(p) // 1.0
    xLens.set(p, 5.0) // Point(x: 5.0, y: 2.0)
    xLens.over { $0 * 3 }(p) // Point(x: 3.0, y: 2.0)
}

// learn(lensManualSet)

// MARK: - Prism

enum Shape {
    case circle(Double)
    case rectangle(Double, Double)
    var circleRadius: Double? {
        guard case let .circle(r) = self else { return nil }
        return r
    }
}

func prism() {
    let circlePrism = prism(\.circleRadius, review: Shape.circle)
    let circle = Shape.circle(5.0)
    let rect = Shape.rectangle(3.0, 4.0)

    // preview — extract if matching
    circlePrism.preview(circle) as Any // Optional(5.0)
    circlePrism.preview(rect) as Any // nil — not a circle

    // review — construct
    circlePrism.review(7.0) // circle(7.0)

    // over — modify if matching, pass through otherwise
    circlePrism.over { $0 * 2 }(circle) // circle(10.0)
    circlePrism.over { $0 * 2 }(rect) // rectangle(3.0, 4.0) — unchanged
}

// learn(prism)

// MARK: - Iso

func iso() {
    let celsiusToFahrenheit = iso(
        get: { (c: Double) in c * 9 / 5 + 32 },
        reverseGet: { (f: Double) in (f - 32) * 5 / 9 }
    )

    celsiusToFahrenheit.get(100) // 212.0
    celsiusToFahrenheit.reverseGet(212) // 100.0
    celsiusToFahrenheit.reverse.get(32) // 0.0

    // over — convert to A, transform, convert back
    celsiusToFahrenheit.over { $0 + 1 }(0) // 0.5555... (add 1°F, convert back)

    // Use as Lens or Prism
    let asLens = celsiusToFahrenheit.asLens
    asLens.get(0) // 32.0
    asLens.set(0, 32) // 0.0 — reverseGet(32)
}

// learn(iso)

// MARK: - Composition

struct Company { var ceo: Person }

func opticsComposition() {
    let ceoLens: Lens<Company, Person> = lens(\.ceo)
    let nameLens: Lens<Person, String> = lens(\.name)

    // Forward composition — read/write deeply
    let ceoNameLens = ceoLens >>> nameLens

    let acme = Company(ceo: Person(name: "Alice", age: 50))

    ceoNameLens.get(acme) // "Alice"
    ceoNameLens.set(acme, "Bob").ceo.name // "Bob"
    ceoNameLens.over { $0.uppercased() }(acme).ceo.name // "ALICE"

    // Backward composition — same result, different reading order
    let ceoNameLens2 = nameLens <<< ceoLens
    ceoNameLens2.get(acme) // "Alice"
}

// learn(opticsComposition)

func lensPrismComposition() {
    // Lens + Prism composes into AffineTraversal
    struct User { var status: Shape }

    let statusLens = lens(\User.status)
    let circlePrism = prism(\.circleRadius, review: Shape.circle)
    let radiusTraversal = statusLens >>> circlePrism // AffineTraversal<User, Double>

    let circleUser = User(status: .circle(3.0))
    let rectUser = User(status: .rectangle(1, 2))

    radiusTraversal.preview(circleUser) as Any // Optional(3.0)
    radiusTraversal.preview(rectUser) as Any // nil
    radiusTraversal.set(circleUser, 7.0).status // circle(7.0)
    radiusTraversal.set(rectUser, 7.0).status // rectangle(1.0, 2.0) — unchanged
}

// learn(lensPrismComposition)

//: [Previous](@previous) | [Next](@next)
