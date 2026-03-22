import Foundation
import Core

public extension Reader {
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
}
