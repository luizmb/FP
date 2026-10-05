// SPDX-License-Identifier: Apache-2.0
import CoreFP
import Foundation

// WriterT + Either — free functions for Writer<W, Either<L, A>>

/// apply for Writer<W, Either>
/// Equals `ap`: `wf >>= \f -> fmap f wa`. Sequential and short-circuiting like `flatMapT`:
/// when the function side fails, the right-hand log is not appended.
func applyWriterEither<W: Monoid, L: Sendable, A: Sendable, B: Sendable>(
    _ wf: Writer<W, Either<L, @Sendable (A) -> B>>,
    _ wa: Writer<W, Either<L, A>>
) -> Writer<W, Either<L, B>> {
    wf.flatMapT { f in wa.mapT(f) }
}

/// liftA2 for Writer<W, Either>
/// Equals `a >>= \x -> fmap (f x) b`. When `a` fails, `b`'s log is not appended.
func liftA2WriterEither<W: Monoid, L: Sendable, A: Sendable, B: Sendable, C: Sendable>(
    _ fn: @escaping @Sendable (A, B) -> C
) -> (Writer<W, Either<L, A>>, Writer<W, Either<L, B>>) -> Writer<W, Either<L, C>> {
    { wa, wb in
        wa.flatMapT { a in wb.mapT { b in fn(a, b) } }
    }
}

/// seqRight for Writer<W, Either>
/// Equals `a >>= \_ -> b`. When `lhs` fails, `rhs`'s log is not appended.
func seqRightWriterEither<W: Monoid, L: Sendable, A: Sendable, B: Sendable>(
    _ lhs: Writer<W, Either<L, A>>,
    _ rhs: Writer<W, Either<L, B>>
) -> Writer<W, Either<L, B>> {
    lhs.flatMapT(const(rhs))
}

/// seqLeft for Writer<W, Either>
/// Equals `a >>= \x -> fmap (const x) b`. When `lhs` fails, `rhs`'s log is not appended.
func seqLeftWriterEither<W: Monoid, L: Sendable, A: Sendable, B: Sendable>(
    _ lhs: Writer<W, Either<L, A>>,
    _ rhs: Writer<W, Either<L, B>>
) -> Writer<W, Either<L, A>> {
    lhs.flatMapT { a in rhs.mapT(const(a)) }
}
