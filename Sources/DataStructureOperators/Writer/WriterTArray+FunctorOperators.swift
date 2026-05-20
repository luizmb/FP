import CoreFP
import CoreFPOperators
import DataStructure

// (<£^>) :: (a -> b) -> Writer<w, [a]> -> Writer<w, [b]>
public func <£^> <W: Monoid, A, B>(_ fn: @escaping @Sendable (A) -> B, _ writer: Writer<W, [A]>) -> Writer<W, [B]> {
    writer.mapT(fn)
}

// (<&^>) :: Writer<w, [a]> -> (a -> b) -> Writer<w, [b]>
public func <&^> <W: Monoid, A, B>(_ writer: Writer<W, [A]>, _ fn: @escaping @Sendable (A) -> B) -> Writer<W, [B]> {
    writer.mapT(fn)
}
