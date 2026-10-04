// SPDX-License-Identifier: Apache-2.0
import Foundation

// AsyncSequenceTResult: outer = AsyncStream, inner = Result
// Type: AsyncStream<Result<A,E>>
// Haskell: ExceptT e AsyncStream

/// flatMapT for AsyncStream<Result<A,E>>
/// .failure(e) → emit .failure(e) once
/// .success(a) → flatten fn(a) elements
@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public func flatMapTAsyncStreamResult<A, B, E: Error>(
    _ stream: AsyncStream<Result<A, E>>,
    _ fn: @escaping @Sendable (A) -> AsyncStream<Result<B, E>>
) -> AsyncStream<Result<B, E>> where A: Sendable, B: Sendable, E: Sendable {
    AsyncStream<Result<B, E>> { continuation in
        let task = Task { @Sendable in
            for await result in stream {
                switch result {
                case let .failure(e):
                    continuation.yield(.failure(e))

                case let .success(a):
                    for await b in fn(a) {
                        continuation.yield(b)
                    }
                }
            }
            continuation.finish()
        }
        // swiftlint:disable:next closure_ignoring_args
        continuation.onTermination = { _ in task.cancel() }
    }
}

/// `bindTAsyncStreamResult`.
@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public func bindTAsyncStreamResult<A, B, E: Error>(
    _ fn: @escaping @Sendable (A) -> AsyncStream<Result<B, E>>
) -> @Sendable (AsyncStream<Result<A, E>>) -> AsyncStream<Result<B, E>> where A: Sendable, B: Sendable, E: Sendable {
    { @Sendable stream in flatMapTAsyncStreamResult(stream, fn) }
}

/// Kleisli composition for AsyncStream<Result<A,E>> (left-to-right)
/// (>=>) :: (a -> AsyncStream<Result<b,e>>) -> (b -> AsyncStream<Result<c,e>>) -> a -> AsyncStream<Result<c,e>>
@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public func kleisliTAsyncStreamResult<A, B, C, E: Error>(
    _ fn1: @escaping @Sendable (A) -> AsyncStream<Result<B, E>>,
    _ fn2: @escaping @Sendable (B) -> AsyncStream<Result<C, E>>
) -> @Sendable (A) -> AsyncStream<Result<C, E>> where B: Sendable, C: Sendable, E: Sendable {
    { a in flatMapTAsyncStreamResult(fn1(a), fn2) }
}
