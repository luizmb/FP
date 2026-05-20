import CoreFP
import CoreFPOperators
import DataStructure

// (>>-) :: Writer<w, [a]> -> (a -> Writer<w, [b]>) -> Writer<w, [b]>
public func >>- <W: Monoid, A, B>(_ writer: Writer<W, [A]>, _ fn: @escaping @Sendable (A) -> Writer<W, [B]>) -> Writer<W, [B]> {
    writer.flatMapT(fn)
}

// (-<<) :: (a -> Writer<w, [b]>) -> Writer<w, [a]> -> Writer<w, [b]>
public func -<< <W: Monoid, A, B>(_ fn: @escaping @Sendable (A) -> Writer<W, [B]>, _ writer: Writer<W, [A]>) -> Writer<W, [B]> {
    writer.flatMapT(fn)
}

// (>=>) :: (a -> Writer<w, [b]>) -> (b -> Writer<w, [c]>) -> a -> Writer<w, [c]>
public func >=> <W: Monoid, A, B, C>(
    _ fn1: @escaping @Sendable (A) -> Writer<W, [B]>,
    _ fn2: @escaping @Sendable (B) -> Writer<W, [C]>
) -> (A) -> Writer<W, [C]> {
    { a in fn1(a).flatMapT(fn2) }
}
