import CoreFP

// AsyncSequenceTArray: AsyncStream<[A]>

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public func <£> <A, B: Sendable>(_ fn: @escaping @Sendable (A) -> B, _ stream: AsyncStream<[A]>) -> AsyncStream<[B]>
where A: Sendable {
    mapTAsyncStreamArray(fn, stream)
}

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public func <&> <A, B: Sendable>(_ stream: AsyncStream<[A]>, _ fn: @escaping @Sendable (A) -> B) -> AsyncStream<[B]>
where A: Sendable {
    mapTAsyncStreamArray(fn, stream)
}
