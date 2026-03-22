import Foundation
import FP
import Writer
import Either

// EitherTWriter: outer = Either, inner = Writer
// Type: Either<L, Writer<W, A>>

public extension Either {
    func mapT<W: Monoid, Inner, C>(_ fn: @escaping (Inner) -> C) -> Either<A, Writer<W, C>>
    where B == Writer<W, Inner> {
        mapRight { writer in writer.fmap(fn) }
    }

    static func fmapT<W: Monoid, Inner, C>(
        _ fn: @escaping (Inner) -> C
    ) -> (Either<A, Writer<W, Inner>>) -> Either<A, Writer<W, C>> {
        { either in either.mapT(fn) }
    }
}
