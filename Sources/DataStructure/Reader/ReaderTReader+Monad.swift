// SPDX-License-Identifier: Apache-2.0
import Foundation

public extension Reader {
    // MARK: - ReaderT + Reader (nested)

    /// Monadic bind for ReaderT Reader
    /// (>>=) :: m a -> (a -> m b) -> m b
    func flatMapT<A, B, Env2>(_ fn: @escaping @Sendable (A) -> Reader<Environment, Reader<Env2, B>>) -> Reader<Environment, Reader<Env2, B>>
    where Output == Reader<Env2, A>, Environment: Sendable {
        Reader<Environment, Reader<Env2, B>> { env1 in
            let innerReader = self.runReader(env1)
            return Reader<Env2, B> { env2 in
                let a = innerReader(env2)
                let resultReader = fn(a).runReader(env1)
                return resultReader(env2)
            }
        }
    }

    /// Curried bind for ReaderT Reader
    static func bindT<A, B, Env2>(
        _ fn: @escaping @Sendable (A) -> Reader<Environment, Reader<Env2, B>>
    ) -> (Reader<Environment, Reader<Env2, A>>) -> Reader<Environment, Reader<Env2, B>>
    where Output == Reader<Env2, A>, Environment: Sendable {
        { reader in
            reader.flatMapT(fn)
        }
    }
}

/// Kleisli composition for `ReaderT + Reader` (left-to-right)
/// (>=>) :: (a -> m b) -> (b -> m c) -> a -> m c
public func kleisliT<Env1: Sendable, Env2: Sendable, A: Sendable, B: Sendable, C: Sendable>(
    _ fn1: @escaping @Sendable (A) -> Reader<Env1, Reader<Env2, B>>,
    _ fn2: @escaping @Sendable (B) -> Reader<Env1, Reader<Env2, C>>
) -> (A) -> Reader<Env1, Reader<Env2, C>> {
    { a in fn1(a).flatMapT(fn2) }
}
