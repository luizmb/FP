#if canImport(Combine)
import Foundation
import FP
import Reader
import Combine
import CombineFP

public extension Reader {
    // MARK: - ReaderT + Publisher

    /// Monadic bind for ReaderT Publisher
    /// (>>=) :: m a -> (a -> m b) -> m b
    @available(macOS 13.0, iOS 16.0, tvOS 16.0, watchOS 9.0, *)
    func flatMapT<A, B, E: Error>(_ fn: @escaping (A) -> Reader<Environment, any Publisher<B, E>>)
    -> Reader<Environment, any Publisher<B, E>>
    where Output == any Publisher<A, E> {
        Reader<Environment, any Publisher<B, E>> { env in
            self.runReader(env).eraseToAnyPublisher().flatMap { a in
                fn(a).runReader(env).eraseToAnyPublisher()
            }.eraseToAnyPublisher()
        }
    }

    /// Curried bind for ReaderT Publisher
    @available(macOS 13.0, iOS 16.0, tvOS 16.0, watchOS 9.0, *)
    static func bindT<A, B, E: Error>(
        _ fn: @escaping (A) -> Reader<Environment, any Publisher<B, E>>
    ) -> (Reader<Environment, any Publisher<A, E>>) -> Reader<Environment, any Publisher<B, E>>
    where Output == any Publisher<A, E> {
        { reader in
            reader.flatMapT(fn)
        }
    }
}

#endif
