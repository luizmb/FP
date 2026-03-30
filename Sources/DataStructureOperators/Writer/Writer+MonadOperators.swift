import CoreFP
import CoreFPOperators
import DataStructure
import Foundation

// (>>-) :: Writer<w, a> -> (a -> Writer<w, b>) -> Writer<w, b>
public func >>- <W: Monoid, A, B>(
    _ writer: Writer<W, A>,
    _ fn: @escaping (A) -> Writer<W, B>
) -> Writer<W, B> {
    writer.flatMap(fn)
}

// (-<<) :: (a -> Writer<w, b>) -> Writer<w, a> -> Writer<w, b>
public func -<< <W: Monoid, A, B>(
    _ fn: @escaping (A) -> Writer<W, B>,
    _ writer: Writer<W, A>
) -> Writer<W, B> {
    writer.flatMap(fn)
}

// (>=>) :: (a -> Writer<w, b>) -> (b -> Writer<w, c>) -> a -> Writer<w, c>
public func >=> <W: Monoid, O0, A, B>(
    _ fn1: @escaping (O0) -> Writer<W, A>,
    _ fn2: @escaping (A) -> Writer<W, B>
) -> (O0) -> Writer<W, B> {
    Writer.kleisli(fn1, fn2)
}
