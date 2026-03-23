import DataStructure
import CoreFPOperators
import CoreFP

// (<£^>) :: (a -> b) -> Writer<w, Either<l, a>> -> Writer<w, Either<l, b>>
public func <£^> <W: Monoid, L, A, B>(_ fn: @escaping (A) -> B, _ writer: Writer<W, Either<L, A>>) -> Writer<W, Either<L, B>> {
    writer.mapT(fn)
}

// (<&^>) :: Writer<w, Either<l, a>> -> (a -> b) -> Writer<w, Either<l, b>>
public func <&^> <W: Monoid, L, A, B>(_ writer: Writer<W, Either<L, A>>, _ fn: @escaping (A) -> B) -> Writer<W, Either<L, B>> {
    writer.mapT(fn)
}
