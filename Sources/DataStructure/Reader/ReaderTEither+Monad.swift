// SPDX-License-Identifier: Apache-2.0
import Foundation

public extension Reader where Environment: Sendable {
    // MARK: - ReaderT + Either

    /// Monadic bind for ReaderT Either
    /// (>>=) :: m a -> (a -> m b) -> m b
    func flatMapT<A, B, L>(_ fn: @escaping @Sendable (A) -> Reader<Environment, Either<L, B>>) -> Reader<Environment, Either<L, B>>
    where Output == Either<L, A> {
        Reader<Environment, Either<L, B>> { env in
            self.runReader(env).flatMap { a in
                fn(a).runReader(env)
            }
        }
    }

    /// Curried bind for ReaderT Either
    static func bindT<A, B, L>(
        _ fn: @escaping @Sendable (A) -> Reader<Environment, Either<L, B>>
    ) -> (Reader<Environment, Either<L, A>>) -> Reader<Environment, Either<L, B>>
    where Output == Either<L, A> {
        { reader in
            reader.flatMapT(fn)
        }
    }
}

/// Kleisli composition for `ReaderT + Either` (left-to-right)
/// (>=>) :: (a -> m b) -> (b -> m c) -> a -> m c
public func kleisliT<Env: Sendable, L: Sendable, A: Sendable, B: Sendable, C: Sendable>(
    _ fn1: @escaping @Sendable (A) -> Reader<Env, Either<L, B>>,
    _ fn2: @escaping @Sendable (B) -> Reader<Env, Either<L, C>>
) -> (A) -> Reader<Env, Either<L, C>> {
    { a in fn1(a).flatMapT(fn2) }
}
