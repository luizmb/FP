import CoreFP
import Foundation

// EitherTStateful: outer = Either, inner = Stateful
// Type: Either<L, Stateful<S, A>>
//
// flatMapT sequences computations structurally: .left propagates;
// .right(stateful) composes via flatMap.

public extension Either {
    /// flatMapT :: Either<l, Stateful<s, a>> -> (a -> Stateful<s, b>) -> Either<l, Stateful<s, b>>
    /// .left(l)           → .left(l)
    /// .right(stateful)   → .right(stateful.flatMap(fn))
    func flatMapT<S, Inner, C>(_ fn: @escaping (Inner) -> Stateful<S, C>) -> Either<A, Stateful<S, C>>
    where B == Stateful<S, Inner> {
        mapRight { stateful in stateful.flatMap(fn) }
    }

    static func bindT<S, Inner, C>(
        _ fn: @escaping (Inner) -> Stateful<S, C>
    ) -> (Either<A, Stateful<S, Inner>>) -> Either<A, Stateful<S, C>> {
        { either in either.flatMapT(fn) }
    }
}
