import Foundation
import FP

// ReaderT + AsyncSequence

/// liftA2 for ReaderT AsyncStream
@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public func liftA2ReaderAsyncStream<Env, A, B, C>(
    _ fn: @escaping @Sendable (A, B) -> C
) -> (Reader<Env, AsyncStream<A>>, Reader<Env, AsyncStream<B>>) -> Reader<Env, AsyncMapSequence<AsyncStream<(A, B)>, C>>
where A: Sendable, B: Sendable, C: Sendable {
    { readerA, readerB in
        Reader { env in
            let streamA = readerA(env)
            let streamB = readerB(env)
            return AsyncStream<(A, B)>.zip(streamA, streamB).map { fn($0.0, $0.1) }
        }
    }
}
