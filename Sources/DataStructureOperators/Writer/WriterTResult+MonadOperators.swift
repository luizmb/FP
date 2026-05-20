import CoreFP
import CoreFPOperators
import DataStructure

// (>>-) :: Writer<w, Result<a, e>> -> (a -> Writer<w, Result<b, e>>) -> Writer<w, Result<b, e>>
public func >>- <W: Monoid, A, B, E: Error>(
    _ writer: Writer<W, Result<A, E>>,
    _ fn: @escaping @Sendable (A) -> Writer<W, Result<B, E>>
) -> Writer<W, Result<B, E>> {
    writer.flatMapT(fn)
}

// (-<<) :: (a -> Writer<w, Result<b, e>>) -> Writer<w, Result<a, e>> -> Writer<w, Result<b, e>>
public func -<< <W: Monoid, A, B, E: Error>(
    _ fn: @escaping @Sendable (A) -> Writer<W, Result<B, E>>,
    _ writer: Writer<W, Result<A, E>>
) -> Writer<W, Result<B, E>> {
    writer.flatMapT(fn)
}

// (>=>) :: (a -> Writer<w, Result<b, e>>) -> (b -> Writer<w, Result<c, e>>) -> a -> Writer<w, Result<c, e>>
public func >=> <W: Monoid, A, B, C, E: Error>(
    _ fn1: @escaping @Sendable (A) -> Writer<W, Result<B, E>>,
    _ fn2: @escaping @Sendable (B) -> Writer<W, Result<C, E>>
) -> (A) -> Writer<W, Result<C, E>> {
    { a in fn1(a).flatMapT(fn2) }
}
