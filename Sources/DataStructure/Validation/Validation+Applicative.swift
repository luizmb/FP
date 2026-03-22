import CoreFP

public extension Validation {
    /// apply :: Validation<e, (a -> b)> -> Validation<e, a> -> Validation<e, b>
    /// THE key operation — accumulates errors via Semigroup.combine instead of short-circuiting.
    static func apply<A0>(_ fns: Validation<E, (A0) -> A>, _ values: Validation<E, A0>) -> Validation<E, A> {
        switch (fns, values) {
        case let (.success(f), .success(a)): .success(f(a))
        case let (.failure(e), .success):    .failure(e)
        case let (.success, .failure(e)):    .failure(e)
        case let (.failure(e1), .failure(e2)): .failure(E.combine(e1, e2))
        }
    }

    /// liftA2 :: (a0 -> a1 -> a) -> Validation<e, a0> -> Validation<e, a1> -> Validation<e, a>
    static func liftA2<A0, A1>(_ fn: @escaping (A0, A1) -> A) -> (Validation<E, A0>, Validation<E, A1>) -> Validation<E, A> {
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
}
