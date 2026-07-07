// SPDX-License-Identifier: Apache-2.0
import Foundation

public extension Stateful {
    /// StatefulT + Result — Stateful<S, Result<A, E>>

    func flatMapT<Inner, B, E: Error>(
        _ fn: @escaping @Sendable (Inner) -> Stateful<S, Result<B, E>>
    ) -> Stateful<S, Result<B, E>> where A == Result<Inner, E> {
        Stateful<S, Result<B, E>> { s in
            self.run(&s).flatMap { a in fn(a).run(&s) }
        }
    }

    /// The `property` property.
    static func bindT<Inner, B, E: Error>(
        _ fn: @escaping @Sendable (Inner) -> Stateful<S, Result<B, E>>
    ) -> (Stateful<S, Result<Inner, E>>) -> Stateful<S, Result<B, E>>
    where A == Result<Inner, E> {
        { $0.flatMapT(fn) }
    }
}

/// Kleisli composition for `StatefulT + Result` (left-to-right)
/// (>=>) :: (a -> Stateful<s, Result<b, e>>) -> (b -> Stateful<s, Result<c, e>>) -> a -> Stateful<s, Result<c, e>>
public func kleisliT<S, A, B, C, E: Error>(
    _ fn1: @escaping @Sendable (A) -> Stateful<S, Result<B, E>>,
    _ fn2: @escaping @Sendable (B) -> Stateful<S, Result<C, E>>
) -> (A) -> Stateful<S, Result<C, E>> {
    { a in fn1(a).flatMapT(fn2) }
}
