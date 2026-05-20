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
