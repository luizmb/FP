import CoreFP

// MARK: - Reader: Semigroup / Monoid
//
// A `Reader<Environment, Output>` whose `Output` is a `Semigroup` or `Monoid` is itself
// a `Semigroup` or `Monoid` under pointwise combination:
//
//   combine(r1, r2) = Reader { env in combine(r1.run(env), r2.run(env)) }
//   identity        = Reader { _ in Output.identity }
//
// This is the standard "reader monad over a monoid" result from functional programming.

extension Reader: Semigroup where Output: Semigroup {
    /// Combines two readers by running both on the same environment and combining
    /// their outputs with `Output.combine`.
    ///
    /// ```swift
    /// let combined = Reader<Int, [String]>.combine(
    ///     Reader { n in (0..<n).map { "item \($0)" } },
    ///     Reader { _ in ["footer"] }
    /// )
    /// combined.runReader(3) // ["item 0", "item 1", "item 2", "footer"]
    /// ```
    ///
    /// - Parameters:
    ///   - lhs: The first reader.
    ///   - rhs: The second reader.
    /// - Returns: A reader that combines both outputs for every environment.
    public static func combine(_ lhs: Self, _ rhs: Self) -> Self {
        Reader { env in .combine(lhs.runReader(env), rhs.runReader(env)) }
    }
}

extension Reader: Monoid where Output: Monoid {
    /// A reader that ignores its environment and returns `Output.identity`.
    ///
    /// ```swift
    /// // In a middleware returning Reader<Environment, Effect<Action>>:
    /// guard case .fetchData = action else { return .identity }
    /// // or, with the expressive alias:
    /// guard case .fetchData = action else { return .doNothing }
    /// ```
    ///
    /// - Note: When `Output` is `Effect<Action>`, `identity` is equivalent to
    ///   `Reader { _ in Effect.empty }` — produce no side-effects for any environment.
    public static var identity: Self { Reader { _ in .identity } }
}

extension Reader where Output: Monoid {
    /// Expressive alias for ``identity`` — produces no output for every environment.
    ///
    /// Reads more naturally than `identity` at call sites where the intent is
    /// "ignore this action":
    ///
    /// ```swift
    /// guard case .fetchData(let query) = action else { return .doNothing }
    /// ```
    public static var doNothing: Self { .identity }
}
