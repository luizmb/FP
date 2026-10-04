// SPDX-License-Identifier: Apache-2.0
import CoreFP

// AsyncSequenceTResult: AsyncStream<Result<A,E>>

/// `>>-` overload.
@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public func >>- <A, B, E: Error>(
    _ stream: AsyncStream<Result<A, E>>,
    _ fn: @escaping @Sendable (A) -> AsyncStream<Result<B, E>>
) -> AsyncStream<Result<B, E>> where A: Sendable, B: Sendable, E: Sendable {
    flatMapTAsyncStreamResult(stream, fn)
}

/// `-` overload.
@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public func -<< <A, B, E: Error>(
    _ fn: @escaping @Sendable (A) -> AsyncStream<Result<B, E>>,
    _ stream: AsyncStream<Result<A, E>>
) -> AsyncStream<Result<B, E>> where A: Sendable, B: Sendable, E: Sendable {
    flatMapTAsyncStreamResult(stream, fn)
}

/// `>=>` overload.
@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public func >=> <A, B, C, E: Error>(
    _ fn1: @escaping @Sendable (A) -> AsyncStream<Result<B, E>>,
    _ fn2: @escaping @Sendable (B) -> AsyncStream<Result<C, E>>
) -> @Sendable (A) -> AsyncStream<Result<C, E>> where B: Sendable, C: Sendable, E: Sendable {
    kleisliTAsyncStreamResult(fn1, fn2)
}

/// `<=<` overload.
@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public func <=< <A, B, C, E: Error>(
    _ fn2: @escaping @Sendable (B) -> AsyncStream<Result<C, E>>,
    _ fn1: @escaping @Sendable (A) -> AsyncStream<Result<B, E>>
) -> @Sendable (A) -> AsyncStream<Result<C, E>> where B: Sendable, C: Sendable, E: Sendable {
    fn1 >=> fn2
}
