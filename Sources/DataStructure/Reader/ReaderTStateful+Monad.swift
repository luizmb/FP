// SPDX-License-Identifier: Apache-2.0
import Foundation

// ReaderTStateful: outer = Reader, inner = Stateful
// Type: Reader<Env, Stateful<S, A>>

public extension Reader {
    /// flatMapT :: Reader<env, Stateful<s, a>> -> (a -> Stateful<s, b>) -> Reader<env, Stateful<s, b>>
    func flatMapT<S, A, B>(_ fn: @escaping @Sendable (A) -> Stateful<S, B>) -> Reader<Environment, Stateful<S, B>>
    where Output == Stateful<S, A> {
        mapReader { stateful in stateful.flatMap(fn) }
    }

    /// The `property` property.
    static func bindT<S, A, B>(
        _ fn: @escaping @Sendable (A) -> Stateful<S, B>
    ) -> (Reader<Environment, Stateful<S, A>>) -> Reader<Environment, Stateful<S, B>>
    where Output == Stateful<S, A> {
        { $0.flatMapT(fn) }
    }
}

/// Kleisli composition for `ReaderT + Stateful` (left-to-right)
/// (>=>) :: (a -> m b) -> (b -> m c) -> a -> m c
public func kleisliT<Env, S, A, B, C>(
    _ fn1: @escaping @Sendable (A) -> Reader<Env, Stateful<S, B>>,
    _ fn2: @escaping @Sendable (B) -> Stateful<S, C>
) -> (A) -> Reader<Env, Stateful<S, C>> {
    { a in fn1(a).flatMapT(fn2) }
}
