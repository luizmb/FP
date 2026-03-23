#if canImport(Combine)
import DataStructure
import CoreFPOperators
import CoreFP
import Combine

// (<*>) :: Writer<w, any Publisher<(a -> b), e>> -> Writer<w, any Publisher<a, e>> -> Writer<w, any Publisher<b, e>>
@available(macOS 13.0, iOS 16.0, tvOS 16.0, watchOS 9.0, *)
public func <*> <W: Monoid, A, B, E: Error>(_ wf: Writer<W, any Publisher<(A) -> B, E>>, _ wa: Writer<W, any Publisher<A, E>>) -> Writer<W, any Publisher<B, E>> {
    applyWriterPublisher(wf, wa)
}

// (*>) :: Writer<w, any Publisher<a, e>> -> Writer<w, any Publisher<b, e>> -> Writer<w, any Publisher<b, e>>
@available(macOS 13.0, iOS 16.0, tvOS 16.0, watchOS 9.0, *)
public func *> <W: Monoid, A, B, E: Error>(_ lhs: Writer<W, any Publisher<A, E>>, _ rhs: Writer<W, any Publisher<B, E>>) -> Writer<W, any Publisher<B, E>> {
    seqRightWriterPublisher(lhs, rhs)
}

// (<*) :: Writer<w, any Publisher<a, e>> -> Writer<w, any Publisher<b, e>> -> Writer<w, any Publisher<a, e>>
@available(macOS 13.0, iOS 16.0, tvOS 16.0, watchOS 9.0, *)
public func <* <W: Monoid, A, B, E: Error>(_ lhs: Writer<W, any Publisher<A, E>>, _ rhs: Writer<W, any Publisher<B, E>>) -> Writer<W, any Publisher<A, E>> {
    seqLeftWriterPublisher(lhs, rhs)
}

#endif
