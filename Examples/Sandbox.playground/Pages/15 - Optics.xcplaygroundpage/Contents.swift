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

func learnLens() {
    let nameLens: Lens<Person, String> = lens(\.name)
    let ageLens:  Lens<Person, Int>    = lens(\.age)

    let alice = Person(name: "Alice", age: 30)

    // get
    print(nameLens.get(alice))                               // "Alice"
    print(ageLens.get(alice))                                // 30

    // set
    print(nameLens.set(alice, "Bob"))                        // Person(name: "Bob", age: 30)
    print(ageLens.set(alice, 31))                            // Person(name: "Alice", age: 31)

    // over — transform the focused value
    print(nameLens.over { $0.uppercased() }(alice))          // Person(name: "ALICE", age: 30)
    print(ageLens.over { $0 + 1 }(alice))                   // Person(name: "Alice", age: 31)
}
// learnLens()

func learnLensManualSet() {
    // For let properties or computed values — provide setter explicitly
    struct Point { let x: Double; let y: Double }

    let xLens = lens(\.x) { p, newX in Point(x: newX, y: p.y) }
    let p = Point(x: 1.0, y: 2.0)

    print(xLens.get(p))                                      // 1.0
    print(xLens.set(p, 5.0))                                 // Point(x: 5.0, y: 2.0)
    print(xLens.over { $0 * 3 }(p))                         // Point(x: 3.0, y: 2.0)
}
// learnLensManualSet()

// MARK: - Prism

enum Shape {
    case circle(Double)
    case rectangle(Double, Double)
    var circleRadius: Double? {
        guard case let .circle(r) = self else { return nil }
        return r
    }
}

func learnPrism() {
    let circlePrism = prism(\.circleRadius, review: Shape.circle)
    let circle = Shape.circle(5.0)
    let rect   = Shape.rectangle(3.0, 4.0)

    // preview — extract if matching
    print(circlePrism.preview(circle) as Any)               // Optional(5.0)
    print(circlePrism.preview(rect) as Any)                 // nil — not a circle

    // review — construct
    print(circlePrism.review(7.0))                          // circle(7.0)

    // over — modify if matching, pass through otherwise
    print(circlePrism.over { $0 * 2 }(circle))             // circle(10.0)
    print(circlePrism.over { $0 * 2 }(rect))               // rectangle(3.0, 4.0) — unchanged
}
// learnPrism()

// MARK: - Iso

func learnIso() {
    let celsiusToFahrenheit = iso(
        get:        { (c: Double) in c * 9 / 5 + 32 },
        reverseGet: { (f: Double) in (f - 32) * 5 / 9 }
    )

    print(celsiusToFahrenheit.get(100))                     // 212.0
    print(celsiusToFahrenheit.reverseGet(212))              // 100.0
    print(celsiusToFahrenheit.reverse.get(32))              // 0.0

    // over — convert to A, transform, convert back
    print(celsiusToFahrenheit.over { $0 + 1 }(0))          // 0.5555... (add 1°F, convert back)

    // Use as Lens or Prism
    let asLens = celsiusToFahrenheit.asLens
    print(asLens.get(0))                                    // 32.0
    print(asLens.set(0, 32))                                // 0.0 — reverseGet(32)
}
// learnIso()

// MARK: - Composition

struct Company { var ceo: Person }

func learnOpticsComposition() {
    let ceoLens:  Lens<Company, Person> = lens(\.ceo)
    let nameLens: Lens<Person, String>  = lens(\.name)

    // Forward composition — read/write deeply
    let ceoNameLens = ceoLens >>> nameLens

    let acme = Company(ceo: Person(name: "Alice", age: 50))

    print(ceoNameLens.get(acme))                            // "Alice"
    print(ceoNameLens.set(acme, "Bob").ceo.name)            // "Bob"
    print(ceoNameLens.over { $0.uppercased() }(acme).ceo.name) // "ALICE"

    // Backward composition — same result, different reading order
    let ceoNameLens2 = nameLens <<< ceoLens
    print(ceoNameLens2.get(acme))                           // "Alice"
}
// learnOpticsComposition()

func learnLensPrismComposition() {
    // Lens + Prism composes into AffineTraversal
    struct User { var status: Shape }

    let statusLens  = lens(\User.status)
    let circlePrism = prism(\.circleRadius, review: Shape.circle)
    let radiusTraversal = statusLens >>> circlePrism         // AffineTraversal<User, Double>

    let circleUser = User(status: .circle(3.0))
    let rectUser   = User(status: .rectangle(1, 2))

    print(radiusTraversal.preview(circleUser) as Any)        // Optional(3.0)
    print(radiusTraversal.preview(rectUser) as Any)          // nil
    print(radiusTraversal.set(circleUser, 7.0).status)       // circle(7.0)
    print(radiusTraversal.set(rectUser, 7.0).status)         // rectangle(1.0, 2.0) — unchanged
}
// learnLensPrismComposition()

//: [Previous](@previous) | [Next](@next)
