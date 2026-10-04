// SPDX-License-Identifier: Apache-2.0
import CoreFPOperators
import DataStructure

// AsyncSequenceTEither: AsyncStream<Either<L,A>>

/// `>>-` overload.
@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public func >>- <L, A, B>(
    _ stream: AsyncStream<Either<L, A>>,
    _ fn: @escaping @Sendable (A) -> AsyncStream<Either<L, B>>
) -> AsyncStream<Either<L, B>> where A: Sendable, B: Sendable, L: Sendable {
    flatMapTAsyncStreamEither(stream, fn)
}

/// `-` overload.
@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public func -<< <L, A, B>(
    _ fn: @escaping @Sendable (A) -> AsyncStream<Either<L, B>>,
    _ stream: AsyncStream<Either<L, A>>
) -> AsyncStream<Either<L, B>> where A: Sendable, B: Sendable, L: Sendable {
    flatMapTAsyncStreamEither(stream, fn)
}

/// `>=>` overload.
@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public func >=> <L, A, B, C>(
    _ fn1: @escaping @Sendable (A) -> AsyncStream<Either<L, B>>,
    _ fn2: @escaping @Sendable (B) -> AsyncStream<Either<L, C>>
) -> @Sendable (A) -> AsyncStream<Either<L, C>> where B: Sendable, C: Sendable, L: Sendable {
    kleisliTAsyncStreamEither(fn1, fn2)
}

/// `<=<` overload.
@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public func <=< <L, A, B, C>(
    _ fn2: @escaping @Sendable (B) -> AsyncStream<Either<L, C>>,
    _ fn1: @escaping @Sendable (A) -> AsyncStream<Either<L, B>>
) -> @Sendable (A) -> AsyncStream<Either<L, C>> where B: Sendable, C: Sendable, L: Sendable {
    fn1 >=> fn2
}
