import Foundation
import FP
import Reader
import Either

public extension Reader {
    // MARK: - ReaderT + Either

    /// Monadic bind for ReaderT Either
    /// (>>=) :: m a -> (a -> m b) -> m b
    func flatMapT<A, B, L>(_ fn: @escaping (A) -> Reader<Environment, Either<L, B>>) -> Reader<Environment, Either<L, B>>
    where Output == Either<L, A> {
        Reader<Environment, Either<L, B>> { env in
            self.runReader(env).flatMap { a in
                fn(a).runReader(env)
            }
        }
    }

    /// Curried bind for ReaderT Either
    static func bindT<A, B, L>(
        _ fn: @escaping (A) -> Reader<Environment, Either<L, B>>
    ) -> (Reader<Environment, Either<L, A>>) -> Reader<Environment, Either<L, B>>
    where Output == Either<L, A> {
        { reader in
            reader.flatMapT(fn)
        }
    }
}
