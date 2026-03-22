import Foundation
import Core

// AsyncSequenceTEither: outer = AsyncStream, inner = Either
// Type: AsyncStream<Either<L,A>>
// Haskell: ExceptT l AsyncStream

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public func flatMapTAsyncStreamEither<L, A, B>(
    _ stream: AsyncStream<Either<L, A>>,
    _ fn: @escaping @Sendable (A) -> AsyncStream<Either<L, B>>
) -> AsyncStream<Either<L, B>> where A: Sendable, B: Sendable, L: Sendable {
    AsyncStream<Either<L, B>> { continuation in
        Task { @Sendable in
            for await either in stream {
                either.match(
                    caseLeft: { l in continuation.yield(.left(l)) },
                    caseRight: { a in
                        Task { @Sendable in
                            for await b in fn(a) {
                                continuation.yield(b)
                            }
                        }
                    }
                )
            }
            continuation.finish()
        }
    }
}

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public func bindTAsyncStreamEither<L, A, B>(
    _ fn: @escaping @Sendable (A) -> AsyncStream<Either<L, B>>
) -> @Sendable (AsyncStream<Either<L, A>>) -> AsyncStream<Either<L, B>> where A: Sendable, B: Sendable, L: Sendable {
    { @Sendable stream in flatMapTAsyncStreamEither(stream, fn) }
}
