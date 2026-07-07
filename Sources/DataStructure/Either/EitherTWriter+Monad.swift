// SPDX-License-Identifier: Apache-2.0
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

    /// The `property` property.
    static func bindT<W: Monoid, Inner, C>(
        _ fn: @escaping @Sendable (Inner) -> Writer<W, C>
    ) -> (Either<A, Writer<W, Inner>>) -> Either<A, Writer<W, C>> {
        { either in either.flatMapT(fn) }
    }
}

/// Kleisli composition for `EitherT + Writer` (left-to-right)
/// (>=>) :: (a -> Either<l, Writer<w, b>>) -> (b -> Writer<w, c>) -> a -> Either<l, Writer<w, c>>
public func kleisliT<L, W: Monoid, A, B, C>(
    _ fn1: @escaping @Sendable (A) -> Either<L, Writer<W, B>>,
    _ fn2: @escaping @Sendable (B) -> Writer<W, C>
) -> (A) -> Either<L, Writer<W, C>> {
    { a in fn1(a).flatMapT(fn2) }
}
