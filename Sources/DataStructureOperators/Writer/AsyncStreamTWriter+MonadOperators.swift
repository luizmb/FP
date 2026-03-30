import CoreFP
import DataStructure
import CoreFPOperators

// (>>-) :: AsyncStream<Writer<w, a>> -> (a -> Writer<w, b>) -> AsyncMapSequence<..., Writer<w, b>>
@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public func >>- <W: Monoid, A, B>(
    _ stream: AsyncStream<Writer<W, A>>,
    _ fn: @escaping @Sendable (A) -> Writer<W, B>
) -> AsyncMapSequence<AsyncStream<Writer<W, A>>, Writer<W, B>> {
    stream.flatMapT(fn)
}

// (-<<) :: (a -> Writer<w, b>) -> AsyncStream<Writer<w, a>> -> AsyncMapSequence<..., Writer<w, b>>
@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public func -<< <W: Monoid, A, B>(
    _ fn: @escaping @Sendable (A) -> Writer<W, B>,
    _ stream: AsyncStream<Writer<W, A>>
) -> AsyncMapSequence<AsyncStream<Writer<W, A>>, Writer<W, B>> {
    stream.flatMapT(fn)
}
