// SPDX-License-Identifier: Apache-2.0
import CoreFP
import Foundation

// EitherTWriter: outer = Either, inner = Writer
// Type: Either<L, Writer<W, A>>

/// apply for EitherTWriter: Either<L,Writer<W,(A->B)>> -> Either<L,Writer<W,A>> -> Either<L,Writer<W,B>>
public func applyEitherWriter<L, W: Monoid, A, B>(
    _ eithF: Either<L, Writer<W, @Sendable (A) -> B>>,
    _ eithA: Either<L, Writer<W, A>>
) -> Either<L, Writer<W, B>> {
    Either.liftA2 { wf, wa in Writer<W, B>(wf.value(wa.value), W.combine(wf.log, wa.log)) }(eithF, eithA)
}

/// liftA2 for EitherTWriter
public func liftA2EitherWriter<L, W: Monoid, A, B, C>(
    _ fn: @escaping @Sendable (A, B) -> C
) -> (Either<L, Writer<W, A>>, Either<L, Writer<W, B>>) -> Either<L, Writer<W, C>> {
    { ea, eb in
        Either.liftA2 { wa, wb in Writer<W, C>(fn(wa.value, wb.value), W.combine(wa.log, wb.log)) }(ea, eb)
    }
}

/// seqRight for EitherTWriter
public func seqRightEitherWriter<L, W: Monoid, A, B>(
    _ lhs: Either<L, Writer<W, A>>,
    _ rhs: Either<L, Writer<W, B>>
) -> Either<L, Writer<W, B>> {
    Either.liftA2 { wa, wb in Writer<W, B>(wb.value, W.combine(wa.log, wb.log)) }(lhs, rhs)
}

/// seqLeft for EitherTWriter
public func seqLeftEitherWriter<L, W: Monoid, A, B>(
    _ lhs: Either<L, Writer<W, A>>,
    _ rhs: Either<L, Writer<W, B>>
) -> Either<L, Writer<W, A>> {
    Either.liftA2 { wa, wb in Writer<W, A>(wa.value, W.combine(wa.log, wb.log)) }(lhs, rhs)
}
