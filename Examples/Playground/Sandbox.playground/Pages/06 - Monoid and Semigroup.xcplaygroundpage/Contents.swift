import FP

// ============================================================
// SEMIGROUP & MONOID
//
// Semigroup: combine :: a -> a -> a  (associative)
// Monoid:    identity :: a           (neutral element)
//
// sconcat — fold non-empty list (Semigroup sufficient)
// mconcat — fold any list      (Monoid needed for empty case)
// <> operator maps to combine
// ============================================================

// MARK: - String

func monoidString() {
    String.combine("Hello, ", "World!") // "Hello, World!"
    sconcat("Hello", [", ", "World", "!"]) // "Hello, World!"
    mconcat(["a", "b", "c"]) // "abc"
    mconcat([String]()) // "" — identity
    "foo" <> "bar" // "foobar" — operator
}

// learn(monoidString)

// MARK: - Array

func monoidArray() {
    [Int].combine([1, 2], [3, 4]) // [1, 2, 3, 4]
    sconcat([1, 2], [[3], [4, 5]]) // [1, 2, 3, 4, 5]
    mconcat([[1, 2], [3], [4, 5]]) // [1, 2, 3, 4, 5]
    mconcat([[Int]]()) // [] — identity
    [1, 2] <> [3, 4] // [1, 2, 3, 4]
    [1, 2] ++ [3, 4] // [1, 2, 3, 4] — ++ also works
}

// learn(monoidArray)

// MARK: - Int (numeric Monoid wrappers)

func monoidInt() {
    // Sum — identity 0
    let s1 = Int.Monoids.Sum(3), s2 = Int.Monoids.Sum(4)
    s1 <> s2 // Sum(7)
    Int.Monoids.Sum.identity // Sum(0)
    mconcat([s1, s2, Int.Monoids.Sum(10)]) // Sum(17)

    // Product — identity 1
    let p1 = Int.Monoids.Product(3), p2 = Int.Monoids.Product(4)
    p1 <> p2 // Product(12)
    Int.Monoids.Product.identity // Product(1)
    mconcat([p1, p2, Int.Monoids.Product(5)]) // Product(60)

    // Min — identity Int.max, collapses to minimum
    let m1 = Int.Monoids.Min(7), m2 = Int.Monoids.Min(3)
    m1 <> m2 // Min(3)
    Int.Monoids.Min.identity // Min(Int.max)
    mconcat([Int.Monoids.Min(5), .init(1), .init(9)]) // Min(1)

    // Max — identity Int.min, collapses to maximum
    let x1 = Int.Monoids.Max(7), x2 = Int.Monoids.Max(3)
    x1 <> x2 // Max(7)
    Int.Monoids.Max.identity // Max(Int.min)
    mconcat([Int.Monoids.Max(5), .init(1), .init(9)]) // Max(9)

    // Works with Double too
    Double.Monoids.Min(2.5) <> Double.Monoids.Min(1.1) // Min(1.1)
    Double.Monoids.Max(2.5) <> Double.Monoids.Max(1.1) // Max(2.5)
}

// learn(monoidInt)

// MARK: - SIMD (element-wise Monoid wrappers)

func monoidSIMD() {
    // Sum — element-wise addition (integer uses &+)
    let s1 = SIMD4<Int>.Monoids.Sum(SIMD4(1, 2, 3, 4))
    let s2 = SIMD4<Int>.Monoids.Sum(SIMD4(10, 20, 30, 40))
    s1 <> s2 // Sum(SIMD4(11, 22, 33, 44))
    SIMD4<Int>.Monoids.Sum.identity // Sum(SIMD4(0, 0, 0, 0))
    mconcat([s1, s2]) // Sum(SIMD4(11, 22, 33, 44))

    // Product — element-wise multiplication (integer uses &*)
    let p1 = SIMD2<Int>.Monoids.Product(SIMD2(3, 5))
    let p2 = SIMD2<Int>.Monoids.Product(SIMD2(4, 2))
    p1 <> p2 // Product(SIMD2(12, 10))
    SIMD2<Int>.Monoids.Product.identity // Product(SIMD2(1, 1))

    // Min — element-wise minimum, identity Scalar.max per lane
    let m1 = SIMD2<Int>.Monoids.Min(SIMD2(5, 1))
    let m2 = SIMD2<Int>.Monoids.Min(SIMD2(2, 7))
    m1 <> m2 // Min(SIMD2(2, 1))

    // Max — element-wise maximum, identity Scalar.min per lane
    let x1 = SIMD2<Int>.Monoids.Max(SIMD2(5, 1))
    let x2 = SIMD2<Int>.Monoids.Max(SIMD2(2, 7))
    x1 <> x2 // Max(SIMD2(5, 7))

    // Works with Float too
    let f1 = SIMD2<Float>.Monoids.Sum(SIMD2(1.5, 2.5))
    let f2 = SIMD2<Float>.Monoids.Sum(SIMD2(0.5, 0.5))
    f1 <> f2 // Sum(SIMD2(2.0, 3.0))

    // mconcat across multiple vectors
    let vs = [SIMD2(5, 9), SIMD2(1, 3), SIMD2(8, 2)].map { SIMD2<Int>.Monoids.Min($0) }
    mconcat(vs) // Min(SIMD2(1, 2))
}

// learn(monoidSIMD)

// MARK: - Bool (Bool.Monoids wrappers)

func monoidBool() {
    // And — conjunction, identity true
    Bool.Monoids.And.combine(.init(true), .init(false)) // And(false)
    Bool.Monoids.And.identity // And(true)
    mconcat([Bool.Monoids.And(true), .init(true)]) // And(true)
    mconcat([Bool.Monoids.And(true), .init(false)]) // And(false)
    mconcat([Bool.Monoids.And]()) // And(true) — identity

    // Or — disjunction, identity false
    Bool.Monoids.Or.combine(.init(false), .init(true)) // Or(true)
    Bool.Monoids.Or.identity // Or(false)
    mconcat([Bool.Monoids.Or(false), .init(false)]) // Or(false)
    mconcat([Bool.Monoids.Or(false), .init(true)]) // Or(true)

    // Xor — exclusive disjunction, identity false
    Bool.Monoids.Xor.combine(.init(true), .init(false)) // Xor(true)
    Bool.Monoids.Xor.combine(.init(true), .init(true)) // Xor(false)
    Bool.Monoids.Xor.identity // Xor(false)
    mconcat([Bool.Monoids.Xor(true), .init(true), .init(true)]) // Xor(true)

    // <> operator works on all
    Bool.Monoids.And(true) <> Bool.Monoids.And(false) // And(false)
    Bool.Monoids.Or(false) <> Bool.Monoids.Or(false) // Or(false)
    Bool.Monoids.Xor(true) <> Bool.Monoids.Xor(true) // Xor(false)
}

// learn(monoidBool)

// MARK: - Optional (Semigroup lifts into Optional)

func monoidOptional() {
    // Optional<A> is a Semigroup/Monoid when A is — same semantics as Haskell's Maybe.
    // Both present → combine wrapped values; one nil → keep the present side; both nil → nil.
    let a: String? = .some("hello")
    let b: String? = .some(" world")
    let none: String? = .none

    Optional<String>.combine(a, b) // Optional("hello world")
    Optional<String>.combine(a, none) // Optional("hello")
    Optional<String>.combine(none, b) // Optional(" world")
    Optional<String>.combine(none, none) // nil
    Optional<String>.identity // nil

    a <> b // Optional("hello world")
    a <> none // Optional("hello")
    mconcat([a, none, b]) // Optional("hello world")
    mconcat([none, none] as [String?]) // nil — identity
}

// learn(monoidOptional)

// MARK: - Result (multiple Monoid strategies)

func monoidResult() {
    // Result has no single canonical Monoid — Haskell's Either faces the same problem.
    // Four newtype wrappers in Result.Monoids let you name your intent explicitly.
    typealias R = Result<String, String>

    // Optimistic — success wins; failures fall through; two failures keep the left.
    // Failure need not be Semigroup.
    let ok1 = R.Monoids.Optimistic(.success("hello"))
    let ok2 = R.Monoids.Optimistic(.success(" world"))
    let err = R.Monoids.Optimistic(.failure("oops"))
    ok1 <> ok2 // .success("hello world")
    ok1 <> err // .success("hello")
    err <> ok1 // .success("hello")
    err <> err // .failure("oops") — left wins

    // OptimisticCombining — success wins; both sides combine when matching.
    // Monoid: identity is .failure(Failure.identity)
    let c1 = R.Monoids.OptimisticCombining(.success("hello"))
    let c2 = R.Monoids.OptimisticCombining(.success(" world"))
    let e1 = R.Monoids.OptimisticCombining(.failure("bad"))
    let e2 = R.Monoids.OptimisticCombining(.failure(" stuff"))
    c1 <> c2 // .success("hello world")
    c1 <> e1 // .success("hello")
    e1 <> e2 // .failure("bad stuff")
    R.Monoids.OptimisticCombining.identity // .failure("") — Failure.identity
    mconcat([c1, e1, c2]) // .success("hello world")

    // Pessimistic — failure wins; successes fall through; two successes keep the left.
    // Success need not be Semigroup.
    let p1 = R.Monoids.Pessimistic(.failure("bad"))
    let p2 = R.Monoids.Pessimistic(.failure(" stuff"))
    let ok = R.Monoids.Pessimistic(.success("hello"))
    p1 <> p2 // .failure("bad stuff")
    p1 <> ok // .failure("bad")
    ok <> p1 // .failure("bad")
    ok <> ok // .success("hello") — left wins

    // PessimisticCombining — failure wins; both sides combine when matching.
    // Monoid: identity is .success(Success.identity)
    let d1 = R.Monoids.PessimisticCombining(.failure("bad"))
    let d2 = R.Monoids.PessimisticCombining(.failure(" stuff"))
    let s1 = R.Monoids.PessimisticCombining(.success("hello"))
    let s2 = R.Monoids.PessimisticCombining(.success(" world"))
    d1 <> d2 // .failure("bad stuff")
    d1 <> s1 // .failure("bad")
    s1 <> s2 // .success("hello world")
    R.Monoids.PessimisticCombining.identity // .success("") — Success.identity
    mconcat([s1, d1, s2]) // .failure("bad")
}

// learn(monoidResult)

// MARK: - Endo (Monoid of endomorphisms)

func monoidEndo() {
    let trim = Endo<String> { $0.trimmingCharacters(in: .whitespaces) }
    let lower = Endo<String> { $0.lowercased() }
    let exclaim = Endo<String> { $0 + "!" }

    // Combine two
    let trimAndLower = trim <> lower
    trimAndLower.runEndo("  HELLO  ") // "hello"

    // mconcat chains the whole list into one transformation
    let normalize = mconcat([trim, lower, exclaim])
    normalize.runEndo("  HELLO  ") // "hello!"
    normalize("  WORLD  ") // "world!" — callAsFunction

    // identity: do-nothing transformation
    Endo<String>.identity.runEndo("hello") // "hello"
    mconcat([Endo<String>]())("hello") // "hello"

    // Free constructor
    let bang = endo { (s: String) in s + "!" }
    bang("hi") // "hi!"
}

// learn(monoidEndo)

//: [Previous](@previous) | [Next](@next)
