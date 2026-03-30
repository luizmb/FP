import Foundation

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
}
