// SPDX-License-Identifier: Apache-2.0
import Foundation

public extension Reader {
    // MARK: - ReaderT + Result

    /// Monadic bind for ReaderT Result
    /// (>>=) :: m a -> (a -> m b) -> m b
    func flatMapT<A, B, E: Error>(_ fn: @escaping @Sendable (A) -> Reader<Environment, Result<B, E>>) -> Reader<Environment, Result<B, E>>
    where Output == Result<A, E> {
        Reader<Environment, Result<B, E>> { env in
            self.runReader(env).flatMap { a in
                fn(a).runReader(env)
            }
        }
    }

    /// Curried bind for ReaderT Result
    static func bindT<A, B, E: Error>(
        _ fn: @escaping @Sendable (A) -> Reader<Environment, Result<B, E>>
    ) -> (Reader<Environment, Result<A, E>>) -> Reader<Environment, Result<B, E>>
    where Output == Result<A, E> {
        { reader in
            reader.flatMapT(fn)
        }
    }
}

/// Kleisli composition for `ReaderT + Result` (left-to-right)
/// (>=>) :: (a -> m b) -> (b -> m c) -> a -> m c
public func kleisliT<Env, A, B, C, E: Error>(
    _ fn1: @escaping @Sendable (A) -> Reader<Env, Result<B, E>>,
    _ fn2: @escaping @Sendable (B) -> Reader<Env, Result<C, E>>
) -> (A) -> Reader<Env, Result<C, E>> {
    { a in fn1(a).flatMapT(fn2) }
}
