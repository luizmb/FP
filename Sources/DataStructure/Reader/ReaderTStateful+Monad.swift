// SPDX-License-Identifier: Apache-2.0
import Foundation

// ReaderTStateful: outer = Reader, inner = Stateful
// Type: Reader<Env, Stateful<S, A>>  (Haskell: ReaderT r (State s))
//
// Bind runs `self` and `fn(a)` with the same environment, threading the state through
// `self`'s Stateful first and then through `fn(a)`'s.

public extension Reader {
    /// flatMapT :: Reader<env, Stateful<s, a>> -> (a -> Reader<env, Stateful<s, b>>) -> Reader<env, Stateful<s, b>>
    func flatMapT<S, A, B>(
        _ fn: @escaping @Sendable (A) -> Reader<Environment, Stateful<S, B>>
    ) -> Reader<Environment, Stateful<S, B>>
    where Output == Stateful<S, A>, Environment: Sendable {
        Reader<Environment, Stateful<S, B>> { env in
            self(env).flatMap { a in fn(a)(env) }
        }
    }

    /// Curried `flatMapT`: lifts a full-stack continuation into a transformation of `ReaderTStateful` values.
    static func bindT<S, A, B>(
        _ fn: @escaping @Sendable (A) -> Reader<Environment, Stateful<S, B>>
    ) -> @Sendable (Reader<Environment, Stateful<S, A>>) -> Reader<Environment, Stateful<S, B>>
    where Output == Stateful<S, A>, Environment: Sendable {
        { $0.flatMapT(fn) }
    }
}

/// Kleisli composition for `ReaderT + Stateful` (left-to-right)
/// (>=>) :: (a -> Reader<env, Stateful<s, b>>) -> (b -> Reader<env, Stateful<s, c>>) -> a -> Reader<env, Stateful<s, c>>
public func kleisliT<Env: Sendable, S, A, B, C>(
    _ fn1: @escaping @Sendable (A) -> Reader<Env, Stateful<S, B>>,
    _ fn2: @escaping @Sendable (B) -> Reader<Env, Stateful<S, C>>
) -> @Sendable (A) -> Reader<Env, Stateful<S, C>> {
    { a in fn1(a).flatMapT(fn2) }
}
