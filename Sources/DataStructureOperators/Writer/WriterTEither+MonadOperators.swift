import CoreFP
import DataStructure
import CoreFPOperators

// (>>-) :: Writer<w, Either<l, a>> -> (a -> Writer<w, Either<l, b>>) -> Writer<w, Either<l, b>>
public func >>- <W: Monoid, L, A, B>(
    _ writer: Writer<W, Either<L, A>>,
    _ fn: @escaping (A) -> Writer<W, Either<L, B>>
) -> Writer<W, Either<L, B>> {
    writer.flatMapT(fn)
}

// (-<<) :: (a -> Writer<w, Either<l, b>>) -> Writer<w, Either<l, a>> -> Writer<w, Either<l, b>>
public func -<< <W: Monoid, L, A, B>(
    _ fn: @escaping (A) -> Writer<W, Either<L, B>>,
    _ writer: Writer<W, Either<L, A>>
) -> Writer<W, Either<L, B>> {
    writer.flatMapT(fn)
}

// (>=>) :: (a -> Writer<w, Either<l, b>>) -> (b -> Writer<w, Either<l, c>>) -> a -> Writer<w, Either<l, c>>
public func >=> <W: Monoid, L, A, B, C>(
    _ fn1: @escaping (A) -> Writer<W, Either<L, B>>,
    _ fn2: @escaping (B) -> Writer<W, Either<L, C>>
) -> (A) -> Writer<W, Either<L, C>> {
    { a in fn1(a).flatMapT(fn2) }
}
