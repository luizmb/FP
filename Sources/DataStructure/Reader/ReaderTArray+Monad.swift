// SPDX-License-Identifier: Apache-2.0
import Foundation

public extension Reader {
    // MARK: - ReaderT + Array

    /// Monadic bind for ReaderT Array
    /// (>>=) :: m a -> (a -> m b) -> m b
    func flatMapT<A, B>(_ fn: @escaping @Sendable (A) -> Reader<Environment, [B]>) -> Reader<Environment, [B]>
    where Output == [A] {
        Reader<Environment, [B]> { env in
            self.runReader(env).flatMap { a in
                fn(a).runReader(env)
            }
        }
    }

    /// Curried bind for ReaderT Array
    static func bindT<A, B>(
        _ fn: @escaping @Sendable (A) -> Reader<Environment, [B]>
    ) -> (Reader<Environment, [A]>) -> Reader<Environment, [B]>
    where Output == [A] {
        { reader in
            reader.flatMapT(fn)
        }
    }
}

/// Kleisli composition for `ReaderT + Array` (left-to-right)
/// (>=>) :: (a -> m b) -> (b -> m c) -> a -> m c
public func kleisliT<Env, A, B, C>(
    _ fn1: @escaping @Sendable (A) -> Reader<Env, [B]>,
    _ fn2: @escaping @Sendable (B) -> Reader<Env, [C]>
) -> (A) -> Reader<Env, [C]> {
    { a in fn1(a).flatMapT(fn2) }
}
