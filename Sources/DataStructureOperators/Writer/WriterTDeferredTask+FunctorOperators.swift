import CoreFP
import CoreFPOperators
import DataStructure

// (<£^>) :: (a -> b) -> Writer<w, DeferredTask<a>> -> Writer<w, DeferredTask<b>>
public func <£^> <W: Monoid, A: Sendable, B: Sendable>(
    _ fn: @escaping @Sendable (A) -> B,
    _ writer: Writer<W, DeferredTask<A>>
) -> Writer<W, DeferredTask<B>> {
    writer.mapT(fn)
}

// (<&^>) :: Writer<w, DeferredTask<a>> -> (a -> b) -> Writer<w, DeferredTask<b>>
public func <&^> <W: Monoid, A: Sendable, B: Sendable>(
    _ writer: Writer<W, DeferredTask<A>>,
    _ fn: @escaping @Sendable (A) -> B
) -> Writer<W, DeferredTask<B>> {
    writer.mapT(fn)
}
