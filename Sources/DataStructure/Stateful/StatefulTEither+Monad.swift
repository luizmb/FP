// SPDX-License-Identifier: Apache-2.0
import Foundation

public extension Stateful {
    /// StatefulT + Either — Stateful<S, Either<L, A>>
    ///
    /// Note: Either.flatMap is @escaping, so we pattern-match directly to avoid
    /// the "inout parameter captured by escaping closure" error.

    func flatMapT<L, Inner, B>(
        _ fn: @escaping @Sendable (Inner) -> Stateful<S, Either<L, B>>
    ) -> Stateful<S, Either<L, B>> where A == Either<L, Inner> {
        Stateful<S, Either<L, B>> { s in
            switch self.run(&s) {
            case let .left(l):
                .left(l)

            case let .right(a):
                fn(a).run(&s)
            }
        }
    }

    /// The `property` property.
    static func bindT<L, Inner, B>(
        _ fn: @escaping @Sendable (Inner) -> Stateful<S, Either<L, B>>
    ) -> (Stateful<S, Either<L, Inner>>) -> Stateful<S, Either<L, B>>
    where A == Either<L, Inner> {
        { $0.flatMapT(fn) }
    }
}

/// Kleisli composition for `StatefulT + Either` (left-to-right)
/// (>=>) :: (a -> Stateful<s, Either<l, b>>) -> (b -> Stateful<s, Either<l, c>>) -> a -> Stateful<s, Either<l, c>>
public func kleisliT<S, L, A, B, C>(
    _ fn1: @escaping @Sendable (A) -> Stateful<S, Either<L, B>>,
    _ fn2: @escaping @Sendable (B) -> Stateful<S, Either<L, C>>
) -> (A) -> Stateful<S, Either<L, C>> {
    { a in fn1(a).flatMapT(fn2) }
}
