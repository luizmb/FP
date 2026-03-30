import CoreFP
import CoreFPOperators
import DataStructure

// (<£^>) :: (a -> b) -> Writer<w, AsyncStream<a>> -> Writer<w, AsyncMapSequence<AsyncStream<a>, b>>
@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public func <£^> <W: Monoid, A, B>(
    _ fn: @escaping @Sendable (A) -> B,
    _ writer: Writer<W, AsyncStream<A>>
) -> Writer<W, AsyncMapSequence<AsyncStream<A>, B>> {
    writer.mapT(fn)
}

// (<&^>) :: Writer<w, AsyncStream<a>> -> (a -> b) -> Writer<w, AsyncMapSequence<AsyncStream<a>, b>>
@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public func <&^> <W: Monoid, A, B>(
    _ writer: Writer<W, AsyncStream<A>>,
    _ fn: @escaping @Sendable (A) -> B
) -> Writer<W, AsyncMapSequence<AsyncStream<A>, B>> {
    writer.mapT(fn)
}
