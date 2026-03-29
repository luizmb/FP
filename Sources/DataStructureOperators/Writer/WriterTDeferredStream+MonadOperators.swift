import CoreFP
import CoreFPOperators
import DataStructure

// (>>-) :: Writer<w, DeferredStream<a>> -> (a -> Writer<w, DeferredStream<b>>) -> Writer<w, DeferredStream<b>>
public func >>- <W: Monoid, A: Sendable, B: Sendable>(
    _ writer: Writer<W, DeferredStream<A>>,
    _ fn: @escaping @Sendable (A) -> Writer<W, DeferredStream<B>>
) -> Writer<W, DeferredStream<B>> {
    writer.flatMapT(fn)
}

// (-<<) :: (a -> Writer<w, DeferredStream<b>>) -> Writer<w, DeferredStream<a>> -> Writer<w, DeferredStream<b>>
public func -<< <W: Monoid, A: Sendable, B: Sendable>(
    _ fn: @escaping @Sendable (A) -> Writer<W, DeferredStream<B>>,
    _ writer: Writer<W, DeferredStream<A>>
) -> Writer<W, DeferredStream<B>> {
    writer.flatMapT(fn)
}

// (>=>) :: (a -> Writer<w, DeferredStream<b>>) -> (b -> Writer<w, DeferredStream<c>>) -> a -> Writer<w, DeferredStream<c>>
public func >=> <W: Monoid, A: Sendable, B: Sendable, C: Sendable>(
    _ fn1: @escaping @Sendable (A) -> Writer<W, DeferredStream<B>>,
    _ fn2: @escaping @Sendable (B) -> Writer<W, DeferredStream<C>>
) -> (A) -> Writer<W, DeferredStream<C>> {
    { a in fn1(a).flatMapT(fn2) }
}
