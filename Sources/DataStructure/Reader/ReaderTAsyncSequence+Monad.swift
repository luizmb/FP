import Foundation
import CoreFP

// ReaderT + AsyncSequence

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public extension Reader {
    /// Monadic flatMap for ReaderT AsyncSequence
    /// (>>=) :: Reader e (AsyncSequence a) -> (a -> Reader e (AsyncSequence b)) -> Reader e (AsyncSequence b)
    func flatMapT<A, B: AsyncSequence>(
        _ fn: @escaping @Sendable (A) async throws -> Reader<Environment, B>
    ) -> Reader<Environment, AsyncThrowingFlatMapSequence<AsyncThrowingMapSequence<AsyncStream<A>, B>, B>>
    where Output == AsyncStream<A>, A: Sendable, Environment: Sendable {
        Reader<Environment, AsyncThrowingFlatMapSequence<AsyncThrowingMapSequence<AsyncStream<A>, B>, B>> { env in
            let stream = self.runReader(env)
            return stream.bind { element in
                try await fn(element).runReader(env)
            }
        }
    }
}

/// Bind for ReaderT AsyncSequence
@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public func bindReaderAsyncStream<Env, A, B: AsyncSequence>(
    _ reader: Reader<Env, AsyncStream<A>>,
    _ fn: @escaping @Sendable (A) async throws -> Reader<Env, B>
) -> Reader<Env, AsyncThrowingFlatMapSequence<AsyncThrowingMapSequence<AsyncStream<A>, B>, B>>
where A: Sendable, Env: Sendable {
    reader.flatMapT(fn)
}
