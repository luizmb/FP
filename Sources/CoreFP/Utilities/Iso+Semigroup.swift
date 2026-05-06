// MARK: - Semigroup / Monoid for Iso<A, A>

// An endomorphism iso (same type on both ends) forms a group under composition:
// `combine` is sequential composition, and `identity` is the do-nothing iso.
//
// Practical use: compose a sequence of lossless transformations into one.
//
// ```swift
// let rotate  = iso(get: rotatePoint,   reverseGet: rotatePointBack)
// let scale   = iso(get: scalePoint,    reverseGet: scalePointBack)
// let translate = iso(get: translatePoint, reverseGet: translatePointBack)
//
// let transform: Iso<Point, Point> = mconcat([rotate, scale, translate])
// transform.get(point)               // all three applied in order
// transform.reverse.get(point)       // all three reversed, in reverse order
// ```

extension Iso: Semigroup where S == A {
    public static func combine(_ lhs: Iso<A, A>, _ rhs: Iso<A, A>) -> Iso<A, A> {
        Iso(
            get: { a in rhs.get(lhs.get(a)) },
            reverseGet: { a in lhs.reverseGet(rhs.reverseGet(a)) }
        )
    }
}

extension Iso: Monoid where S == A {
    public static var identity: Iso<A, A> { .id }
}
