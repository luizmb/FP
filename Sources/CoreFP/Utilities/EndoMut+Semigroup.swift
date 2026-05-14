// MARK: - Semigroup / Monoid for EndoMut<A>

// In-place endomorphisms form a Monoid under sequential application:
// `combine(f, g)` applies f first, then g — rhs sees every mutation lhs made.
// `identity` is the do-nothing closure — leaves every value unchanged.

extension EndoMut: Semigroup {
    /// Combines two in-place endomorphisms by sequential application: `lhs` runs first, then `rhs`.
    ///
    /// The combined `EndoMut` applies both mutations to the same `inout` value.
    /// No copy is made between the two mutations — `rhs` sees every change `lhs` made.
    ///
    /// ```swift
    /// let clamp = EndoMut<[Int]> { xs in xs = xs.map { min($0, 100) } }
    /// let sort  = EndoMut<[Int]> { $0.sort() }
    /// let both  = EndoMut.combine(clamp, sort)
    /// var items = [200, 5, 50]
    /// both(&items)   // [5, 50, 100]
    /// ```
    public static func combine(_ lhs: EndoMut<A>, _ rhs: EndoMut<A>) -> EndoMut<A> {
        EndoMut { a in
            lhs.runEndoMut(&a)
            rhs.runEndoMut(&a)
        }
    }
}

extension EndoMut: Monoid {
    /// The identity in-place endomorphism — the do-nothing closure.
    public static var identity: EndoMut<A> {
        EndoMut { _ in }
    }
}
