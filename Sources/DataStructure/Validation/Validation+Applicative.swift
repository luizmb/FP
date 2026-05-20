import CoreFP

public extension Validation {
    /// apply :: Validation<e, (a -> b)> -> Validation<e, a> -> Validation<e, b>
    /// THE key operation — accumulates errors via Semigroup.combine instead of short-circuiting.
    static func apply<A0>(_ fns: Validation<E, @Sendable (A0) -> A>, _ values: Validation<E, A0>) -> Validation<E, A> {
        switch (fns, values) {
        case let (.success(f), .success(a)): .success(f(a))
        case let (.failure(e), .success):    .failure(e)
        case let (.success, .failure(e)):    .failure(e)
        case let (.failure(e1), .failure(e2)): .failure(E.combine(e1, e2))
        }
    }

    /// liftA2 :: (a0 -> a1 -> a) -> Validation<e, a0> -> Validation<e, a1> -> Validation<e, a>
    static func liftA2<A0, A1>(_ fn: @escaping @Sendable (A0, A1) -> A) -> @Sendable (Validation<E, A0>, Validation<E, A1>) -> Validation<E, A> {
        { va0, va1 in
            switch (va0, va1) {
            case let (.success(a0), .success(a1)):   .success(fn(a0, a1))
            case let (.failure(e), .success):        .failure(e)
            case let (.success, .failure(e)):        .failure(e)
            case let (.failure(e1), .failure(e2)):   .failure(E.combine(e1, e2))
            }
        }
    }

    /// seqRight — accumulates errors, returns right value
    func seqRight<B>(_ rhs: Validation<E, B>) -> Validation<E, B> {
        Validation<E, B>.liftA2({ _, b in b })(self, rhs)
    }

    /// seqLeft — accumulates errors, returns left value
    func seqLeft<B>(_ rhs: Validation<E, B>) -> Validation<E, A> {
        Validation<E, A>.liftA2({ a, _ in a })(self, rhs)
    }

    /// zip :: Validation<e, a1> -> Validation<e, a2> -> Validation<e, (a1, a2)>
    /// Accumulates errors from both sides via Semigroup.
    static func zip<A1, A2>(_ v1: Validation<E, A1>, _ v2: Validation<E, A2>) -> Validation<E, A>
    where A == (A1, A2) {
        Validation<E, (A1, A2)>.liftA2({ ($0, $1) })(v1, v2)
    }

    /// zip3 :: Validation<e, a1> -> Validation<e, a2> -> Validation<e, a3> -> Validation<e, (a1, a2, a3)>
    /// Accumulates errors from all three sides via Semigroup.
    static func zip3<A1, A2, A3>(
        _ v1: Validation<E, A1>,
        _ v2: Validation<E, A2>,
        _ v3: Validation<E, A3>
    ) -> Validation<E, A>
    where A == (A1, A2, A3) {
        Validation<E, (A1, A2, A3)>.liftA2({ ab, c in (ab.0, ab.1, c) })(
            Validation<E, (A1, A2)>.zip(v1, v2),
            v3
        )
    }

    /// zip4 :: Validation<e, a1> -> … -> Validation<e, a4> -> Validation<e, (a1, a2, a3, a4)>
    /// Accumulates errors from all four sides via Semigroup.
    static func zip4<A1, A2, A3, A4>(
        _ v1: Validation<E, A1>,
        _ v2: Validation<E, A2>,
        _ v3: Validation<E, A3>,
        _ v4: Validation<E, A4>
    ) -> Validation<E, A>
    where A == (A1, A2, A3, A4) {
        Validation<E, (A1, A2, A3, A4)>.liftA2({ abc, d in (abc.0, abc.1, abc.2, d) })(
            Validation<E, (A1, A2, A3)>.zip3(v1, v2, v3),
            v4
        )
    }
}
