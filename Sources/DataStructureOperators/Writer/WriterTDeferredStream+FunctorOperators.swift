import CoreFP
import DataStructure
import CoreFPOperators

// (<£^>) :: (a -> b) -> Writer<w, DeferredStream<a>> -> Writer<w, DeferredStream<b>>
public func <£^> <W: Monoid, A: Sendable, B: Sendable>(
    _ fn: @escaping @Sendable (A) -> B,
    _ writer: Writer<W, DeferredStream<A>>
) -> Writer<W, DeferredStream<B>> {
    writer.mapT(fn)
}

// (<&^>) :: Writer<w, DeferredStream<a>> -> (a -> b) -> Writer<w, DeferredStream<b>>
public func <&^> <W: Monoid, A: Sendable, B: Sendable>(
    _ writer: Writer<W, DeferredStream<A>>,
    _ fn: @escaping @Sendable (A) -> B
) -> Writer<W, DeferredStream<B>> {
    writer.mapT(fn)
}
