// SPDX-License-Identifier: Apache-2.0
import CoreFP
import Foundation

// EitherTWriter: outer = Either, inner = Writer
// Type: Either<L, Writer<W, A>>  (Haskell: WriterT w (Either l) a)
//
// flatMapT is WriterT's bind: the continuation returns the full stack, so it can fail
// (`.left`) as well as log. `.left` short-circuits; logs combine left to right.

extension Either {
    /// flatMapT :: Either<l, Writer<w, a>> -> (a -> Either<l, Writer<w, c>>) -> Either<l, Writer<w, c>>
    /// .left(l)   → .left(l)
    /// .right(w1) → fn(w1.value): .left(l) → .left(l); .right(w2) → .right(Writer(w2.value, w1.log <> w2.log))
    func flatMapT<W: Monoid, Inner, C>(
        _ fn: (Inner) -> Either<A, Writer<W, C>>
    ) -> Either<A, Writer<W, C>>
    where B == Writer<W, Inner> {
        switch self {
        case let .left(left):
            .left(left)

        case let .right(w1):
            switch fn(w1.value) {
            case let .left(left):
                .left(left)

            case let .right(w2):
                .right(Writer(w2.value, W.combine(w1.log, w2.log)))
            }
        }
    }

    /// bindT :: (a -> Either<l, Writer<w, c>>) -> Either<l, Writer<w, a>> -> Either<l, Writer<w, c>>
    static func bindT<W: Monoid, Inner, C>(
        _ fn: @escaping @Sendable (Inner) -> Either<A, Writer<W, C>>
    ) -> @Sendable (Either<A, Writer<W, Inner>>) -> Either<A, Writer<W, C>> {
        { either in either.flatMapT(fn) }
    }
}

/// Kleisli composition for `EitherT + Writer` (left-to-right)
/// (>=>) :: (a -> Either<l, Writer<w, b>>) -> (b -> Either<l, Writer<w, c>>) -> a -> Either<l, Writer<w, c>>
func kleisliT<L, W: Monoid, A, B, C>(
    _ fn1: @escaping @Sendable (A) -> Either<L, Writer<W, B>>,
    _ fn2: @escaping @Sendable (B) -> Either<L, Writer<W, C>>
) -> @Sendable (A) -> Either<L, Writer<W, C>> {
    { a in fn1(a).flatMapT(fn2) }
}
