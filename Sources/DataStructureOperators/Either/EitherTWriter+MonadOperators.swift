import DataStructure
import CoreFP
import CoreFPOperators

// EitherTWriter: outer = Either, inner = Writer
// Type: Either<L, Writer<W, A>>

// (>>-) :: Either<l, Writer<w, a>> -> (a -> Writer<w, b>) -> Either<l, Writer<w, b>>
public func >>- <L, W: Monoid, A, B>(_ either: Either<L, Writer<W, A>>, _ fn: @escaping (A) -> Writer<W, B>) -> Either<L, Writer<W, B>> {
    either.flatMapT(fn)
}

// (-<<) :: (a -> Writer<w, b>) -> Either<l, Writer<w, a>> -> Either<l, Writer<w, b>>
public func -<< <L, W: Monoid, A, B>(_ fn: @escaping (A) -> Writer<W, B>, _ either: Either<L, Writer<W, A>>) -> Either<L, Writer<W, B>> {
    either.flatMapT(fn)
}

// (>=>) :: (a -> Either<l, Writer<w, b>>) -> (b -> Writer<w, c>) -> a -> Either<l, Writer<w, c>>
public func >=> <L, W: Monoid, A, B, C>(
    _ fn1: @escaping (A) -> Either<L, Writer<W, B>>,
    _ fn2: @escaping (B) -> Writer<W, C>
) -> (A) -> Either<L, Writer<W, C>> {
    { a in fn1(a).flatMapT(fn2) }
}
