// SPDX-License-Identifier: Apache-2.0
import CoreFP

// AsyncSequenceTArray: AsyncStream<[A]>

/// `>>-` overload.
@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public func >>- <A, B>(_ stream: AsyncStream<[A]>, _ fn: @escaping @Sendable (A) -> AsyncStream<[B]>) -> AsyncStream<[B]>
where A: Sendable, B: Sendable {
    flatMapTAsyncStreamArray(stream, fn)
}

/// `-` overload.
@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public func -<< <A, B>(_ fn: @escaping @Sendable (A) -> AsyncStream<[B]>, _ stream: AsyncStream<[A]>) -> AsyncStream<[B]>
where A: Sendable, B: Sendable {
    flatMapTAsyncStreamArray(stream, fn)
}
