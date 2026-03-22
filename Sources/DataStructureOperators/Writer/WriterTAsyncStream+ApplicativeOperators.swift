import DataStructure
import CoreFPOperators
import CoreFP

// (*>) :: Writer<w, AsyncStream<a>> -> Writer<w, AsyncStream<b>> -> Writer<w, AsyncMapSequence<...>>
// Note: <*> is not available — AsyncStream has no apply free function due to its complex return type.
// Use liftA2WriterAsyncStream for general applicative lifting.
@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public func *> <W: Monoid, A: Sendable, B: Sendable>(
    _ lhs: Writer<W, AsyncStream<A>>,
    _ rhs: Writer<W, AsyncStream<B>>
) -> Writer<W, AsyncMapSequence<AsyncStream<(A, B)>, B>> {
    seqRightWriterAsyncStream(lhs, rhs)
}

// (<*) :: Writer<w, AsyncStream<a>> -> Writer<w, AsyncStream<b>> -> Writer<w, AsyncMapSequence<...>>
@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public func <* <W: Monoid, A: Sendable, B: Sendable>(
    _ lhs: Writer<W, AsyncStream<A>>,
    _ rhs: Writer<W, AsyncStream<B>>
) -> Writer<W, AsyncMapSequence<AsyncStream<(A, B)>, A>> {
    seqLeftWriterAsyncStream(lhs, rhs)
}
