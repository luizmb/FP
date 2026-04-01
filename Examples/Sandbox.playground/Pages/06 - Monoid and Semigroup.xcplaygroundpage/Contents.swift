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

func learnMonoidString() {
    print(String.combine("Hello, ", "World!"))               // "Hello, World!"
    print(sconcat("Hello", [", ", "World", "!"]))            // "Hello, World!"
    print(mconcat(["a", "b", "c"]))                          // "abc"
    print(mconcat([String]()))                               // "" — identity
    print("foo" <> "bar")                                    // "foobar" — operator
}
// learnMonoidString()

// MARK: - Array

func learnMonoidArray() {
    print([Int].combine([1, 2], [3, 4]))                     // [1, 2, 3, 4]
    print(sconcat([1, 2], [[3], [4, 5]]))                    // [1, 2, 3, 4, 5]
    print(mconcat([[1, 2], [3], [4, 5]]))                    // [1, 2, 3, 4, 5]
    print(mconcat([[Int]]()))                                // [] — identity
    print([1, 2] <> [3, 4])                                  // [1, 2, 3, 4]
    print([1, 2] ++ [3, 4])                                  // [1, 2, 3, 4] — ++ also works
}
// learnMonoidArray()

// MARK: - Int (numeric Monoid wrappers)

func learnMonoidInt() {
    // Sum
    let s1 = Int.Monoids.Sum(3), s2 = Int.Monoids.Sum(4)
    print(s1 <> s2)                                          // Sum(7)
    print(Int.Monoids.Sum.identity)                          // Sum(0)
    print(mconcat([s1, s2, Int.Monoids.Sum(10)]))            // Sum(17)

    // Product
    let p1 = Int.Monoids.Product(3), p2 = Int.Monoids.Product(4)
    print(p1 <> p2)                                          // Product(12)
    print(Int.Monoids.Product.identity)                      // Product(1)

    // Min / Max
    let vals: [Int.Monoids.Min] = [.init(5), .init(2), .init(9)]
    print(mconcat(vals))                                     // Min(2)
    let vals2: [Int.Monoids.Max] = [.init(5), .init(2), .init(9)]
    print(mconcat(vals2))                                    // Max(9)
}
// learnMonoidInt()

// MARK: - Optional (Semigroup lifts into Optional)

func learnMonoidOptional() {
    let a: String? = .some("hello")
    let b: String? = .some(" world")
    let none: String? = .none

    print(Optional<String>.combine(a, b))                    // Optional("hello world")
    print(Optional<String>.combine(a, none))                 // Optional("hello")
    print(Optional<String>.combine(none, b))                 // Optional(" world")
    print(a <> b)                                            // Optional("hello world")
    print(a <> none)                                         // Optional("hello")
}
// learnMonoidOptional()

// MARK: - Endo (Monoid of endomorphisms)

func learnMonoidEndo() {
    let trim    = Endo<String> { $0.trimmingCharacters(in: .whitespaces) }
    let lower   = Endo<String> { $0.lowercased() }
    let exclaim = Endo<String> { $0 + "!" }

    // Combine two
    let trimAndLower = trim <> lower
    print(trimAndLower.runEndo("  HELLO  "))                 // "hello"

    // mconcat chains the whole list into one transformation
    let normalize = mconcat([trim, lower, exclaim])
    print(normalize.runEndo("  HELLO  "))                    // "hello!"
    print(normalize("  WORLD  "))                            // "world!" — callAsFunction

    // identity: do-nothing transformation
    print(Endo<String>.identity.runEndo("hello"))            // "hello"
    print(mconcat([Endo<String>]())("hello"))                // "hello"

    // Free constructor
    let bang = endo { (s: String) in s + "!" }
    print(bang("hi"))                                        // "hi!"
}
// learnMonoidEndo()

//: [Previous](@previous) | [Next](@next)
