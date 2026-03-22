import CoreFP

// ValidationTWriter: outer = Validation, inner = Writer
// Type: Validation<E, Writer<W, A>>
// Outer Validation accumulates errors; success case combines Writer values and logs.

public func applyValidationWriter<E: Semigroup, W: Monoid, A, B>(
    _ vf: Validation<E, Writer<W, (A) -> B>>,
    _ va: Validation<E, Writer<W, A>>
) -> Validation<E, Writer<W, B>> {
    Validation.liftA2(Writer.apply)(vf, va)
}

public func liftA2ValidationWriter<E: Semigroup, W: Monoid, A, B, C>(
    _ fn: @escaping (A, B) -> C
) -> (Validation<E, Writer<W, A>>, Validation<E, Writer<W, B>>) -> Validation<E, Writer<W, C>> {
    Validation.liftA2(Writer.liftA2(fn))
}

public func seqRightValidationWriter<E: Semigroup, W: Monoid, A, B>(
    _ lhs: Validation<E, Writer<W, A>>,
    _ rhs: Validation<E, Writer<W, B>>
) -> Validation<E, Writer<W, B>> {
    Validation.liftA2({ (wa: Writer<W, A>, wb: Writer<W, B>) in wa.seqRight(wb) })(lhs, rhs)
}

public func seqLeftValidationWriter<E: Semigroup, W: Monoid, A, B>(
    _ lhs: Validation<E, Writer<W, A>>,
    _ rhs: Validation<E, Writer<W, B>>
) -> Validation<E, Writer<W, A>> {
    Validation.liftA2({ (wa: Writer<W, A>, wb: Writer<W, B>) in wa.seqLeft(wb) })(lhs, rhs)
}
