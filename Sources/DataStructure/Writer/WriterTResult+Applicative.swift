// SPDX-License-Identifier: Apache-2.0
import CoreFP
import Foundation

// WriterT + Result — free functions for Writer<W, Result<A, E>>

/// apply for Writer<W, Result>
/// Equals `ap`: `wf >>= \f -> fmap f wa`. Sequential and short-circuiting like `flatMapT`:
/// when the function side fails, the right-hand log is not appended.
func applyWriterResult<W: Monoid, A, B, E: Error>(
    _ wf: Writer<W, Result<@Sendable (A) -> B, E>>,
    _ wa: Writer<W, Result<A, E>>
) -> Writer<W, Result<B, E>> {
    wf.flatMapT { f in wa.mapT(f) }
}

/// liftA2 for Writer<W, Result>
/// Equals `a >>= \x -> fmap (f x) b`. When `a` fails, `b`'s log is not appended.
func liftA2WriterResult<W: Monoid, A, B, C, E: Error>(
    _ fn: @escaping @Sendable (A, B) -> C
) -> (Writer<W, Result<A, E>>, Writer<W, Result<B, E>>) -> Writer<W, Result<C, E>> {
    { wa, wb in
        wa.flatMapT { a in wb.mapT { b in fn(a, b) } }
    }
}

/// seqRight for Writer<W, Result>
/// Equals `a >>= \_ -> b`. When `lhs` fails, `rhs`'s log is not appended.
func seqRightWriterResult<W: Monoid, A, B, E: Error>(
    _ lhs: Writer<W, Result<A, E>>,
    _ rhs: Writer<W, Result<B, E>>
) -> Writer<W, Result<B, E>> {
    lhs.flatMapT(const(rhs))
}

/// seqLeft for Writer<W, Result>
/// Equals `a >>= \x -> fmap (const x) b`. When `lhs` fails, `rhs`'s log is not appended.
func seqLeftWriterResult<W: Monoid, A, B, E: Error>(
    _ lhs: Writer<W, Result<A, E>>,
    _ rhs: Writer<W, Result<B, E>>
) -> Writer<W, Result<A, E>> {
    lhs.flatMapT { a in rhs.mapT(const(a)) }
}
