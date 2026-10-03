// SPDX-License-Identifier: Apache-2.0
import CoreFP
import Foundation

// WriterT + Optional — free functions for Writer<W, A?>

/// apply for Writer<W, Optional>
/// Equals `ap`: `wf >>= \f -> fmap f wa`. Sequential and short-circuiting like `flatMapT`:
/// when the function side fails, the right-hand log is not appended.
public func applyWriterOptional<W: Monoid, A, B>(
    _ wf: Writer<W, (@Sendable (A) -> B)?>,
    _ wa: Writer<W, A?>
) -> Writer<W, B?> {
    wf.flatMapT { f in wa.mapT(f) }
}

/// liftA2 for Writer<W, Optional>
/// Equals `a >>= \x -> fmap (f x) b`. When `a` fails, `b`'s log is not appended.
public func liftA2WriterOptional<W: Monoid, A, B, C>(
    _ fn: @escaping @Sendable (A, B) -> C
) -> (Writer<W, A?>, Writer<W, B?>) -> Writer<W, C?> {
    { wa, wb in
        wa.flatMapT { a in wb.mapT { b in fn(a, b) } }
    }
}

/// seqRight for Writer<W, Optional>
/// Equals `a >>= \_ -> b`. When `lhs` fails, `rhs`'s log is not appended.
public func seqRightWriterOptional<W: Monoid, A, B>(
    _ lhs: Writer<W, A?>,
    _ rhs: Writer<W, B?>
) -> Writer<W, B?> {
    lhs.flatMapT(const(rhs))
}

/// seqLeft for Writer<W, Optional>
/// Equals `a >>= \x -> fmap (const x) b`. When `lhs` fails, `rhs`'s log is not appended.
public func seqLeftWriterOptional<W: Monoid, A, B>(
    _ lhs: Writer<W, A?>,
    _ rhs: Writer<W, B?>
) -> Writer<W, A?> {
    lhs.flatMapT { a in rhs.mapT(const(a)) }
}
