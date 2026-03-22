import Core

// AsyncSequenceTArray: AsyncStream<[A]>

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public func *> <A, B>(_ lhs: AsyncStream<[A]>, _ rhs: AsyncStream<[B]>) -> AsyncStream<[B]>
where A: Sendable, B: Sendable {
    seqRightAsyncStreamArray(lhs, rhs)
}

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public func <* <A, B>(_ lhs: AsyncStream<[A]>, _ rhs: AsyncStream<[B]>) -> AsyncStream<[A]>
where A: Sendable, B: Sendable {
    seqLeftAsyncStreamArray(lhs, rhs)
}
