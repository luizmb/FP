import Core

// AsyncSequenceTOptional: AsyncStream<A?>

// (*>) :: AsyncStream<a?> -> AsyncStream<b?> -> AsyncStream<b?>
@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public func *> <A, B>(_ lhs: AsyncStream<A?>, _ rhs: AsyncStream<B?>) -> AsyncStream<B?>
where A: Sendable, B: Sendable {
    seqRightAsyncStreamOptional(lhs, rhs)
}

// (<*) :: AsyncStream<a?> -> AsyncStream<b?> -> AsyncStream<a?>
@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public func <* <A, B>(_ lhs: AsyncStream<A?>, _ rhs: AsyncStream<B?>) -> AsyncStream<A?>
where A: Sendable, B: Sendable {
    seqLeftAsyncStreamOptional(lhs, rhs)
}
