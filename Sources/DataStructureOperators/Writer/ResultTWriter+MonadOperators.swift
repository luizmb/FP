import CoreFP
import DataStructure
import CoreFPOperators

// (>>-) :: Result<Writer<w, a>, e> -> (a -> Writer<w, b>) -> Result<Writer<w, b>, e>
public func >>- <W: Monoid, A, B, E: Error>(
    _ result: Result<Writer<W, A>, E>,
    _ fn: @escaping (A) -> Writer<W, B>
) -> Result<Writer<W, B>, E> {
    result.flatMapT(fn)
}

// (-<<) :: (a -> Writer<w, b>) -> Result<Writer<w, a>, e> -> Result<Writer<w, b>, e>
public func -<< <W: Monoid, A, B, E: Error>(
    _ fn: @escaping (A) -> Writer<W, B>,
    _ result: Result<Writer<W, A>, E>
) -> Result<Writer<W, B>, E> {
    result.flatMapT(fn)
}

// (>=>) :: (a -> Result<Writer<w, b>, e>) -> (b -> Writer<w, c>) -> a -> Result<Writer<w, c>, e>
public func >=> <W: Monoid, A, B, C, E: Error>(
    _ fn1: @escaping (A) -> Result<Writer<W, B>, E>,
    _ fn2: @escaping (B) -> Writer<W, C>
) -> (A) -> Result<Writer<W, C>, E> {
    { a in fn1(a).flatMapT(fn2) }
}
