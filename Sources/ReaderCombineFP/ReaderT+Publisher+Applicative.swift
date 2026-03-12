#if canImport(Combine)
import Foundation
import FP
import Reader
import Combine
import CombineFP

// ReaderT + Publisher

@available(macOS 13.0, iOS 16.0, tvOS 16.0, watchOS 9.0, *)
public func applyReaderPublisher<Env, A, B, E: Error>(
    _ readerF: Reader<Env, any Publisher<(A) -> B, E>>,
    _ readerA: Reader<Env, any Publisher<A, E>>
) -> Reader<Env, any Publisher<B, E>> {
    Reader { env in
        let publisherF = readerF(env).eraseToAnyPublisher()
        let publisherA = readerA(env).eraseToAnyPublisher()
        return publisherF.zip(publisherA).map { fn, a in fn(a) }.eraseToAnyPublisher()
    }
}

/// liftA2 for ReaderT Publisher
@available(macOS 13.0, iOS 16.0, tvOS 16.0, watchOS 9.0, *)
public func liftA2ReaderPublisher<Env, A, B, C, E: Error>(
    _ fn: @escaping (A, B) -> C
) -> (Reader<Env, any Publisher<A, E>>, Reader<Env, any Publisher<B, E>>) -> Reader<Env, any Publisher<C, E>> {
    { readerA, readerB in
        Reader { env in
            let publisherA = readerA(env).eraseToAnyPublisher()
            let publisherB = readerB(env).eraseToAnyPublisher()
            return publisherA.zip(publisherB).map(fn).eraseToAnyPublisher()
        }
    }
}

#endif
