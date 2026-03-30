import CoreFP
import DataStructure
import CoreFPOperators

// (<£^>) :: (a -> b) -> AsyncStream<Writer<w, a>> -> AsyncMapSequence<AsyncStream<Writer<w, a>>, Writer<w, b>>
@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public func <£^> <W: Monoid, A, B>(
    _ fn: @escaping @Sendable (A) -> B,
    _ stream: AsyncStream<Writer<W, A>>
) -> AsyncMapSequence<AsyncStream<Writer<W, A>>, Writer<W, B>> {
    stream.mapT(fn)
}

// (<&^>) :: AsyncStream<Writer<w, a>> -> (a -> b) -> AsyncMapSequence<AsyncStream<Writer<w, a>>, Writer<w, b>>
@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public func <&^> <W: Monoid, A, B>(
    _ stream: AsyncStream<Writer<W, A>>,
    _ fn: @escaping @Sendable (A) -> B
) -> AsyncMapSequence<AsyncStream<Writer<W, A>>, Writer<W, B>> {
    stream.mapT(fn)
}
