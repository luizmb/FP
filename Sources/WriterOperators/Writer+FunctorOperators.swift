import Foundation
import FP
import Writer
import Operators

// (<$>) :: (a -> b) -> Writer<w, a> -> Writer<w, b>
public func <£> <W: Monoid, A, B>(
    _ transform: @escaping (A) -> B,
    _ writer: Writer<W, A>
) -> Writer<W, B> {
    writer.fmap(transform)
}

// ($>) :: Writer<w, a> -> b -> Writer<w, b>
public func £> <W: Monoid, A, B>(
    _ writer: Writer<W, A>,
    _ value: B
) -> Writer<W, B> {
    writer.fmap(const(value))
}

// (<$) :: b -> Writer<w, a> -> Writer<w, b>
public func <£ <W: Monoid, A, B>(
    _ value: B,
    _ writer: Writer<W, A>
) -> Writer<W, B> {
    writer £> value
}

// (<&>) :: Writer<w, a> -> (a -> b) -> Writer<w, b>
public func <&> <W: Monoid, A, B>(
    _ writer: Writer<W, A>,
    _ transform: @escaping (A) -> B
) -> Writer<W, B> {
    writer.mapWriter(transform)
}
