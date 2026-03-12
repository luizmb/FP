import Foundation
import FP

public extension Reader {
    // MARK: - ReaderT + Optional

    /// Monadic bind for ReaderT Optional
    /// (>>=) :: m a -> (a -> m b) -> m b
    func flatMapT<A, B>(_ fn: @escaping (A) -> Reader<Environment, B?>) -> Reader<Environment, B?>
    where Output == A? {
        Reader<Environment, B?> { env in
            self.runReader(env).flatMap { a in
                fn(a).runReader(env)
            }
        }
    }

    /// Curried bind for ReaderT Optional
    static func bindT<A, B>(
        _ fn: @escaping (A) -> Reader<Environment, B?>
    ) -> (Reader<Environment, A?>) -> Reader<Environment, B?>
    where Output == A? {
        { reader in
            reader.flatMapT(fn)
        }
    }

    // MARK: - ReaderT + Result

    /// Monadic bind for ReaderT Result
    /// (>>=) :: m a -> (a -> m b) -> m b
    func flatMapT<A, B, E: Error>(_ fn: @escaping (A) -> Reader<Environment, Result<B, E>>) -> Reader<Environment, Result<B, E>>
    where Output == Result<A, E> {
        Reader<Environment, Result<B, E>> { env in
            self.runReader(env).flatMap { a in
                fn(a).runReader(env)
            }
        }
    }

    /// Curried bind for ReaderT Result
    static func bindT<A, B, E: Error>(
        _ fn: @escaping (A) -> Reader<Environment, Result<B, E>>
    ) -> (Reader<Environment, Result<A, E>>) -> Reader<Environment, Result<B, E>>
    where Output == Result<A, E> {
        { reader in
            reader.flatMapT(fn)
        }
    }

    // MARK: - ReaderT + Reader (nested)

    /// Monadic bind for ReaderT Reader
    /// (>>=) :: m a -> (a -> m b) -> m b
    func flatMapT<A, B, Env2>(_ fn: @escaping (A) -> Reader<Environment, Reader<Env2, B>>) -> Reader<Environment, Reader<Env2, B>>
    where Output == Reader<Env2, A> {
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
        _ fn: @escaping (A) -> Reader<Environment, Reader<Env2, B>>
    ) -> (Reader<Environment, Reader<Env2, A>>) -> Reader<Environment, Reader<Env2, B>>
    where Output == Reader<Env2, A> {
        { reader in
            reader.flatMapT(fn)
        }
    }

    // MARK: - ReaderT + Array

    /// Monadic bind for ReaderT Array
    /// (>>=) :: m a -> (a -> m b) -> m b
    func flatMapT<A, B>(_ fn: @escaping (A) -> Reader<Environment, [B]>) -> Reader<Environment, [B]>
    where Output == [A] {
        Reader<Environment, [B]> { env in
            self.runReader(env).flatMap { a in
                fn(a).runReader(env)
            }
        }
    }

    /// Curried bind for ReaderT Array
    static func bindT<A, B>(
        _ fn: @escaping (A) -> Reader<Environment, [B]>
    ) -> (Reader<Environment, [A]>) -> Reader<Environment, [B]>
    where Output == [A] {
        { reader in
            reader.flatMapT(fn)
        }
    }
}
