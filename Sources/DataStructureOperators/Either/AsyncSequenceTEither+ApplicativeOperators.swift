import DataStructure
import CoreFP
import CoreFPOperators

// AsyncSequenceTEither: AsyncStream<Either<L,A>>

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public func *> <L, A, B>(_ lhs: AsyncStream<Either<L, A>>, _ rhs: AsyncStream<Either<L, B>>) -> AsyncStream<Either<L, B>>
where A: Sendable, B: Sendable, L: Sendable {
    seqRightAsyncStreamEither(lhs, rhs)
}

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public func <* <L, A, B>(_ lhs: AsyncStream<Either<L, A>>, _ rhs: AsyncStream<Either<L, B>>) -> AsyncStream<Either<L, A>>
where A: Sendable, B: Sendable, L: Sendable {
    seqLeftAsyncStreamEither(lhs, rhs)
}
