// SPDX-License-Identifier: Apache-2.0
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
    func flatMapT<S, Inner, C>(_ fn: @escaping @Sendable (Inner) -> Stateful<S, C>) -> Either<A, Stateful<S, C>>
    where B == Stateful<S, Inner> {
        mapRight { stateful in stateful.flatMap(fn) }
    }

    /// The `property` property.
    static func bindT<S, Inner, C>(
        _ fn: @escaping @Sendable (Inner) -> Stateful<S, C>
    ) -> (Either<A, Stateful<S, Inner>>) -> Either<A, Stateful<S, C>> {
        { either in either.flatMapT(fn) }
    }
}

/// Kleisli composition for `EitherT + Stateful` (left-to-right)
/// (>=>) :: (a -> Either<l, Stateful<s, b>>) -> (b -> Stateful<s, c>) -> a -> Either<l, Stateful<s, c>>
public func kleisliT<L, S, A, B, C>(
    _ fn1: @escaping @Sendable (A) -> Either<L, Stateful<S, B>>,
    _ fn2: @escaping @Sendable (B) -> Stateful<S, C>
) -> (A) -> Either<L, Stateful<S, C>> {
    { a in fn1(a).flatMapT(fn2) }
}
