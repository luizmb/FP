// MARK: - Semigroup / Monoid for Endo<A>

// Endomorphisms form a Monoid under left-to-right composition:
// `combine(f, g)` applies f first, then g.
// `identity` is the do-nothing function — leaves every value unchanged.

extension Endo: Semigroup {
    public static func combine(_ lhs: Endo<A>, _ rhs: Endo<A>) -> Endo<A> {
        Endo { a in rhs.runEndo(lhs.runEndo(a)) }
    }
}

extension Endo: Monoid {
    public static var identity: Endo<A> {
        Endo { $0 }
    }
}
