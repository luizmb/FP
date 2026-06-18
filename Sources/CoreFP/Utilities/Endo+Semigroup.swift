// SPDX-License-Identifier: Apache-2.0
// MARK: - Semigroup / Monoid for Endo<A>

// Endomorphisms form a Monoid under left-to-right composition:
// `combine(f, g)` applies f first, then g.
// `identity` is the do-nothing function — leaves every value unchanged.

extension Endo: Semigroup {
    /// Combines two endomorphisms by sequential application: `lhs` runs first, then `rhs`.
    ///
    /// ```swift
    /// let trim  = Endo<String> { $0.trimmingCharacters(in: .whitespaces) }
    /// let lower = Endo<String> { $0.lowercased() }
    /// let both  = Endo.combine(trim, lower)
    /// both("  HELLO  ")  // "hello"
    /// ```
    public static func combine(_ lhs: Endo<A>, _ rhs: Endo<A>) -> Endo<A> {
        Endo { a in rhs.runEndo(lhs.runEndo(a)) }
    }
}

extension Endo: Monoid {
    /// The identity endomorphism — the do-nothing function.
    public static var identity: Endo<A> {
        Endo { $0 }
    }
}
