import CoreFP

// WriterTValidation: outer = Writer, inner = Validation
// Type: Writer<W, Validation<E, A>>
// Combines logs left-to-right; accumulates Validation errors.

public func applyWriterValidation<W: Monoid, E: Semigroup, A, B>(
    _ wf: Writer<W, Validation<E, @Sendable (A) -> B>>,
    _ wa: Writer<W, Validation<E, A>>
) -> Writer<W, Validation<E, B>> {
    Writer<W, Validation<E, B>>(
        Validation.apply(wf.value, wa.value),
        W.combine(wf.log, wa.log)
    )
}

public func liftA2WriterValidation<W: Monoid, E: Semigroup, A, B, C>(
    _ fn: @escaping @Sendable (A, B) -> C
) -> (Writer<W, Validation<E, A>>, Writer<W, Validation<E, B>>) -> Writer<W, Validation<E, C>> {
    { wa, wb in
        Writer<W, Validation<E, C>>(
            Validation.liftA2(fn)(wa.value, wb.value),
            W.combine(wa.log, wb.log)
        )
    }
}

public func seqRightWriterValidation<W: Monoid, E: Semigroup, A, B>(
    _ lhs: Writer<W, Validation<E, A>>,
    _ rhs: Writer<W, Validation<E, B>>
) -> Writer<W, Validation<E, B>> {
    Writer<W, Validation<E, B>>(lhs.value.seqRight(rhs.value), W.combine(lhs.log, rhs.log))
}

public func seqLeftWriterValidation<W: Monoid, E: Semigroup, A, B>(
    _ lhs: Writer<W, Validation<E, A>>,
    _ rhs: Writer<W, Validation<E, B>>
) -> Writer<W, Validation<E, A>> {
    Writer<W, Validation<E, A>>(lhs.value.seqLeft(rhs.value), W.combine(lhs.log, rhs.log))
}
