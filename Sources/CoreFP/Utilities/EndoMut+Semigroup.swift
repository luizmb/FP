// MARK: - Semigroup / Monoid for EndoMut<A>

// In-place endomorphisms form a Monoid under sequential application:
// `combine(f, g)` applies f first, then g — rhs sees every mutation lhs made.
// `identity` is the do-nothing closure — leaves every value unchanged.

extension EndoMut: Semigroup {
    public static func combine(_ lhs: EndoMut<A>, _ rhs: EndoMut<A>) -> EndoMut<A> {
        EndoMut { a in
            lhs.runEndoMut(&a)
            rhs.runEndoMut(&a)
        }
    }
}

extension EndoMut: Monoid {
    public static var identity: EndoMut<A> {
        EndoMut { _ in }
    }
}
