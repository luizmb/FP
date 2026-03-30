import CoreFP
import DataStructure
import CoreFPOperators

// (<£^>) :: (a -> b) -> Writer<w, a?> -> Writer<w, b?>
public func <£^> <W: Monoid, A, B>(_ fn: @escaping (A) -> B, _ writer: Writer<W, A?>) -> Writer<W, B?> {
    writer.mapT(fn)
}

// (<&^>) :: Writer<w, a?> -> (a -> b) -> Writer<w, b?>
public func <&^> <W: Monoid, A, B>(_ writer: Writer<W, A?>, _ fn: @escaping (A) -> B) -> Writer<W, B?> {
    writer.mapT(fn)
}
