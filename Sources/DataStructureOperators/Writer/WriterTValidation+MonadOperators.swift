import CoreFP
import DataStructure
import CoreFPOperators

// (>>-) :: Writer<w, Validation<e, a>> -> (a -> Writer<w, Validation<e, b>>) -> Writer<w, Validation<e, b>>
public func >>- <W: Monoid, E: Semigroup, A, B>(
    _ writer: Writer<W, Validation<E, A>>,
    _ fn: @escaping (A) -> Writer<W, Validation<E, B>>
) -> Writer<W, Validation<E, B>> {
    writer.flatMapT(fn)
}

// (-<<) :: (a -> Writer<w, Validation<e, b>>) -> Writer<w, Validation<e, a>> -> Writer<w, Validation<e, b>>
public func -<< <W: Monoid, E: Semigroup, A, B>(
    _ fn: @escaping (A) -> Writer<W, Validation<E, B>>,
    _ writer: Writer<W, Validation<E, A>>
) -> Writer<W, Validation<E, B>> {
    writer.flatMapT(fn)
}

// (>=>) :: (a -> Writer<w, Validation<e,b>>) -> (b -> Writer<w, Validation<e,c>>) -> a -> Writer<w, Validation<e,c>>
public func >=> <W: Monoid, E: Semigroup, A, B, C>(
    _ fn1: @escaping (A) -> Writer<W, Validation<E, B>>,
    _ fn2: @escaping (B) -> Writer<W, Validation<E, C>>
) -> (A) -> Writer<W, Validation<E, C>> {
    { a in fn1(a).flatMapT(fn2) }
}
