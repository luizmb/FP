import CoreFP

// MARK: - Reader: Semigroup / Monoid
//
// A `Reader<Environment, Output>` whose `Output` is a `Semigroup` or `Monoid` is itself
// a `Semigroup` or `Monoid` under pointwise combination — a standard result from
// functional programming (analogous to `(r -> a)` being a Monoid when `a` is a Monoid
// in Haskell):
//
//   combine(r1, r2) = Reader { env in combine(r1.run(env), r2.run(env)) }
//   identity        = pure(.identity)       -- constant reader returning Output.identity

extension Reader: Semigroup where Output: Semigroup {
    /// Combines two `Reader`s by running both on the same environment and merging
    /// their outputs with `Output.combine`.
    ///
    /// ```swift
    /// let combined = Reader<Int, [String]>.combine(
    ///     Reader { n in (0..<n).map { "item \($0)" } },
    ///     Reader { _ in ["footer"] }
    /// )
    /// combined.runReader(3) // ["item 0", "item 1", "item 2", "footer"]
    /// ```
    public static func combine(_ lhs: Self, _ rhs: Self) -> Self {
        Reader { env in .combine(lhs.runReader(env), rhs.runReader(env)) }
    }
}

extension Reader: Monoid where Output: Monoid {
    /// The identity `Reader`: lifts `Output.identity` into the Reader context via
    /// ``pure(_:)``, producing the same value for every environment.
    ///
    /// ```swift
    /// Reader<MyEnv, [String]>.identity.runReader(env) // []
    /// ```
    public static var identity: Self { .pure(.identity) }
}
