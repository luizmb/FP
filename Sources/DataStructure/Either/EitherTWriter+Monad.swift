import CoreFP
import Foundation

// EitherTWriter: outer = Either, inner = Writer
// Type: Either<L, Writer<W, A>>
//
// flatMapT sequences computations structurally: .left propagates;
// .right(writer) composes via flatMap, accumulating the log.

public extension Either {
    /// flatMapT :: Either<l, Writer<w, a>> -> (a -> Writer<w, b>) -> Either<l, Writer<w, b>>
    /// .left(l)         → .left(l)
    /// .right(writer)   → .right(writer.flatMap(fn))
    func flatMapT<W: Monoid, Inner, C>(_ fn: @escaping @Sendable (Inner) -> Writer<W, C>) -> Either<A, Writer<W, C>>
    where B == Writer<W, Inner> {
        mapRight { writer in writer.flatMap(fn) }
    }

    static func bindT<W: Monoid, Inner, C>(
        _ fn: @escaping @Sendable (Inner) -> Writer<W, C>
    ) -> (Either<A, Writer<W, Inner>>) -> Either<A, Writer<W, C>> {
        { either in either.flatMapT(fn) }
    }
}
