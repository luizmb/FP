import CoreFP
import CoreFPOperators
import DataStructure

// (<£^>) :: (a -> b) -> Writer<w, Validation<e, a>> -> Writer<w, Validation<e, b>>
public func <£^> <W: Monoid, E: Semigroup, A, B>(
    _ fn: @escaping @Sendable (A) -> B,
    _ writer: Writer<W, Validation<E, A>>
) -> Writer<W, Validation<E, B>> {
    writer.mapT(fn)
}

// (<&^>) :: Writer<w, Validation<e, a>> -> (a -> b) -> Writer<w, Validation<e, b>>
public func <&^> <W: Monoid, E: Semigroup, A, B>(
    _ writer: Writer<W, Validation<E, A>>,
    _ fn: @escaping @Sendable (A) -> B
) -> Writer<W, Validation<E, B>> {
    writer.mapT(fn)
}
