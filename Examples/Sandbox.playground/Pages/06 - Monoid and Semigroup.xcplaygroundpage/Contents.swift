import FP

// ============================================================
// SEMIGROUP & MONOID
// Semigroup: combine :: a -> a -> a  (associative binary op)
// Monoid:    identity :: a           (neutral element for combine)
//
// Monoid extends Semigroup with an identity element such that:
//   combine(identity, x) == x
//   combine(x, identity) == x
//
// sconcat: fold a non-empty structure (Semigroup sufficient)
// mconcat: fold any structure, using identity for empty (needs Monoid)
// ============================================================

// MARK: - String (Semigroup and Monoid via concatenation)

// String.combine("Hello, ", "World!")      // "Hello, World!"
// sconcat("Hello", [", ", "World", "!"])   // "Hello, World!"
// mconcat(["a", "b", "c"])                 // "abc"
// mconcat([])                              // "" — identity
// "foo" <> "bar"                           // "foobar" — operator


// MARK: - Array (Semigroup and Monoid via concatenation)

// [Int].combine([1, 2], [3, 4])            // [1, 2, 3, 4]
// sconcat([1, 2], [[3], [4, 5]])           // [1, 2, 3, 4, 5]
// mconcat([[1, 2], [3], [4, 5]])           // [1, 2, 3, 4, 5]
// mconcat([[Int]]())                       // [] — identity
// [1, 2] <> [3, 4]                         // [1, 2, 3, 4]
// [1, 2] ++ [3, 4]                         // [1, 2, 3, 4] — ++ is also available


// MARK: - Int (numeric Monoid wrappers)
// Int itself can be a Monoid in multiple ways (sum, product, min, max).
// The library provides wrapper types via Int.Monoids.

// --- Additive (sum) ---
// let s1 = Int.Monoids.Sum(3)
// let s2 = Int.Monoids.Sum(4)
// Int.Monoids.Sum.combine(s1, s2)          // Sum(7)
// s1 <> s2                                 // Sum(7)
// Int.Monoids.Sum.identity                 // Sum(0)
// mconcat([s1, s2, Int.Monoids.Sum(10)])   // Sum(17)

// --- Multiplicative (product) ---
// let p1 = Int.Monoids.Product(3)
// let p2 = Int.Monoids.Product(4)
// p1 <> p2                                 // Product(12)
// Int.Monoids.Product.identity             // Product(1)
// mconcat([p1, p2, Int.Monoids.Product(2)])  // Product(24)

// --- Min ---
// let m1 = Int.Monoids.Min(3)
// let m2 = Int.Monoids.Min(7)
// m1 <> m2                                 // Min(3)
// mconcat([Int.Monoids.Min(5), .init(2), .init(9)])  // Min(2)

// --- Max ---
// let x1 = Int.Monoids.Max(3)
// let x2 = Int.Monoids.Max(7)
// x1 <> x2                                 // Max(7)
// mconcat([Int.Monoids.Max(5), .init(2), .init(9)])  // Max(9)


// MARK: - Optional (Semigroup lifts into Optional)
// Optional<A: Semigroup> is itself a Semigroup: .none is identity-like.

// let a: String? = .some("hello")
// let b: String? = .some(" world")
// let none: String? = .none

// Optional<String>.combine(a, b)           // .some("hello world")
// Optional<String>.combine(a, none)        // .some("hello") — none treated as identity
// Optional<String>.combine(none, b)        // .some(" world")
// a <> b                                   // .some("hello world")
// a <> none                                // .some("hello")


// MARK: - Endo (Monoid of endomorphisms: (a -> a) under composition)
// Endo<A> wraps (A) -> A. The Monoid operation is composition.
// mconcat chains a list of transformations into one.

// let trim    = Endo<String> { $0.trimmingCharacters(in: .whitespaces) }
// let lower   = Endo<String> { $0.lowercased() }
// let exclaim = Endo<String> { $0 + "!" }

// --- Combine two ---
// let trimAndLower = trim <> lower
// trimAndLower.runEndo("  HELLO  ")        // "hello"

// --- Fold a list of transformations into one ---
// let normalize = mconcat([trim, lower, exclaim])
// normalize.runEndo("  HELLO  ")           // "hello!"
// normalize("  HELLO  ")                   // "hello!" — callAsFunction

// --- identity: the do-nothing transformation ---
// Endo<String>.identity.runEndo("hello")   // "hello"
// mconcat([Endo<String>]())("hello")       // "hello" — empty list = identity


// MARK: - Writer (Monoid accumulation in disguise)
// Writer<W: Monoid, A> uses Monoid.combine to merge logs during flatMap.

// let w1 = Writer(1, "started; ")
// let w2 = w1.flatMap { n in Writer(n + 1, "incremented; ") }
// let w3 = w2.flatMap { n in Writer(n * 2, "doubled; ") }
// w3.runWriter()                           // (4, "started; incremented; doubled; ")
// w3.execWriter()                          // "started; incremented; doubled; "

//: [Previous](@previous) | [Next](@next)
