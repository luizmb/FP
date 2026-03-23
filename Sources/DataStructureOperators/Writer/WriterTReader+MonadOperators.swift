import DataStructure
import CoreFPOperators
import CoreFP

// (>>-) :: Writer<w, Reader<env, a>> -> (a -> Writer<w, Reader<env, b>>) -> Writer<w, Reader<env, b>>
public func >>- <W: Monoid, Env, A, B>(_ writer: Writer<W, Reader<Env, A>>, _ fn: @escaping (A) -> Writer<W, Reader<Env, B>>) -> Writer<W, Reader<Env, B>> {
    writer.flatMapT(fn)
}

// (-<<) :: (a -> Writer<w, Reader<env, b>>) -> Writer<w, Reader<env, a>> -> Writer<w, Reader<env, b>>
public func -<< <W: Monoid, Env, A, B>(_ fn: @escaping (A) -> Writer<W, Reader<Env, B>>, _ writer: Writer<W, Reader<Env, A>>) -> Writer<W, Reader<Env, B>> {
    writer.flatMapT(fn)
}

// (>=>) :: (a -> Writer<w, Reader<env, b>>) -> (b -> Writer<w, Reader<env, c>>) -> a -> Writer<w, Reader<env, c>>
public func >=> <W: Monoid, Env, A, B, C>(
    _ fn1: @escaping (A) -> Writer<W, Reader<Env, B>>,
    _ fn2: @escaping (B) -> Writer<W, Reader<Env, C>>
) -> (A) -> Writer<W, Reader<Env, C>> {
    { a in fn1(a).flatMapT(fn2) }
}
