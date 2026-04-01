import FP

// ============================================================
// OPTICS: Lens, Prism, Iso, AffineTraversal
//
// Optics are composable tools for focusing on parts of a structure.
//
//   Lens<S, A>     — focus on a field that always exists
//   Prism<S, A>    — focus on a case that may or may not match
//   Iso<S, A>      — a lossless bidirectional conversion
//   AffineTraversal — a Prism with a setter (optional focus with set)
//
// All optics compose via >>> (forward) and <<< (backward).
// A Lens composed with a Prism gives an AffineTraversal, etc.
// ============================================================

// MARK: - Lens<S, A>
// get :: S -> A
// set :: (S, A) -> S
// over :: (A -> A) -> S -> S

// struct Person {
//     var name: String
//     var age: Int
// }

// --- From WritableKeyPath (automatic getter and setter) ---
// let nameLens: Lens<Person, String> = lens(\.name)
// let ageLens:  Lens<Person, Int>    = lens(\.age)

// let alice = Person(name: "Alice", age: 30)

// --- get ---
// nameLens.get(alice)                      // "Alice"
// ageLens.get(alice)                       // 30

// --- set ---
// nameLens.set(alice, "Bob")               // Person(name: "Bob", age: 30)
// ageLens.set(alice, 31)                   // Person(name: "Alice", age: 31)

// --- over: transform the focused value ---
// nameLens.over { $0.uppercased() }(alice)  // Person(name: "ALICE", age: 30)
// ageLens.over { $0 + 1 }(alice)           // Person(name: "Alice", age: 31)

// --- From KeyPath with explicit setter (for let properties) ---
// struct Point { let x: Double; let y: Double }
// let xLens = lens(\.x) { p, newX in Point(x: newX, y: p.y) }
// let p = Point(x: 1.0, y: 2.0)
// xLens.get(p)                             // 1.0
// xLens.set(p, 5.0)                        // Point(x: 5.0, y: 2.0)


// MARK: - Prism<S, A>
// preview :: S -> A?   (try to extract the focused value)
// review  :: A -> S    (construct S from A)
// over    :: (A -> A) -> S -> S

// enum Shape {
//     case circle(Double)
//     case rectangle(Double, Double)
//
//     var circleRadius: Double? {
//         guard case let .circle(r) = self else { return nil }
//         return r
//     }
// }

// let circlePrism = prism(\.circleRadius, review: Shape.circle)

// let circle = Shape.circle(5.0)
// let rect   = Shape.rectangle(3.0, 4.0)

// --- preview: extract if matching ---
// circlePrism.preview(circle)              // Optional(5.0)
// circlePrism.preview(rect)               // nil — not a circle

// --- review: construct ---
// circlePrism.review(7.0)                  // Shape.circle(7.0)

// --- over: modify if matching, pass through otherwise ---
// circlePrism.over { $0 * 2 }(circle)     // Shape.circle(10.0)
// circlePrism.over { $0 * 2 }(rect)       // Shape.rectangle(3.0, 4.0) — unchanged

// --- Prism from explicit functions ---
// let explicitPrism = prism(
//     preview: { (s: Shape) -> Double? in guard case let .circle(r) = s else { return nil }; return r },
//     review: Shape.circle
// )


// MARK: - Iso<S, A>
// get        :: S -> A
// reverseGet :: A -> S
// reverse    :: Iso<A, S>
// over       :: (A -> A) -> S -> S
// asLens     :: Lens<S, A>
// asPrism    :: Prism<S, A>

// --- Celsius <-> Fahrenheit ---
// let celsiusToFahrenheit = iso(
//     get:        { (c: Double) in c * 9 / 5 + 32 },
//     reverseGet: { (f: Double) in (f - 32) * 5 / 9 }
// )

// celsiusToFahrenheit.get(100)             // 212.0
// celsiusToFahrenheit.reverseGet(212)      // 100.0
// celsiusToFahrenheit.reverse.get(32)      // 0.0

// --- over: round-trip transform ---
// celsiusToFahrenheit.over { $0 + 1 }(100)  // 100.555... (add 1°F, convert back)

// --- Use as Lens or Prism ---
// let asLens = celsiusToFahrenheit.asLens
// asLens.get(0)                            // 32.0
// asLens.set(0, 32)                        // 0.0 — reverseGet(32)


// MARK: - Optics Composition (>>> and <<<)
// Optics compose just like functions. The types work out automatically.

// struct Company {
//     var ceo: Person
// }
// struct Person {
//     var name: String
//     var age:  Int
// }

// let ceoLens:  Lens<Company, Person> = lens(\.ceo)
// let nameLens: Lens<Person, String>  = lens(\.name)

// --- Forward composition (ceo -> name) ---
// let ceoNameLens = ceoLens >>> nameLens

// let acme = Company(ceo: Person(name: "Alice", age: 50))
// ceoNameLens.get(acme)                    // "Alice"
// ceoNameLens.set(acme, "Bob")             // Company(ceo: Person("Bob", 50))
// ceoNameLens.over { $0.uppercased() }(acme)  // Company(ceo: Person("ALICE", 50))

// --- Backward composition (same result, different order) ---
// let ceoNameLens2 = nameLens <<< ceoLens  // same Lens<Company, String>

// --- Compose Lens with Prism (gives AffineTraversal) ---
// enum Status { case active(String); case inactive }
// struct User { var status: Status }
// let statusLens = lens(\User.status)
// let activePrism = prism(
//     preview: { (s: Status) -> String? in guard case let .active(msg) = s else { return nil }; return msg },
//     review: Status.active
// )
// let activeMessageTraversal = statusLens >>> activePrism   // AffineTraversal<User, String>
// let user = User(status: .active("online"))
// activeMessageTraversal.preview(user)                     // Optional("online")
// activeMessageTraversal.set(user, "away")                 // User(status: .active("away"))

//: [Previous](@previous) | [Next](@next)
