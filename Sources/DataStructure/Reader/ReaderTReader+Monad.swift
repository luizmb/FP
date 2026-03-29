import CoreFP
import Foundation

public extension Reader {
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
}
