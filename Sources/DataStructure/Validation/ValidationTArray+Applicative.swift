import CoreFP

// ValidationTArray: outer = Validation, inner = Array
// Type: Validation<E, [A]>

public func applyValidationArray<E: Semigroup, A, B>(
    _ vf: Validation<E, [(A) -> B]>,
    _ va: Validation<E, [A]>
) -> Validation<E, [B]> {
    Validation.liftA2(Array.apply)(vf, va)
}

public func liftA2ValidationArray<E: Semigroup, A, B, C>(
    _ fn: @escaping @Sendable (A, B) -> C
) -> (Validation<E, [A]>, Validation<E, [B]>) -> Validation<E, [C]> {
    Validation.liftA2(Array.liftA2(fn))
}

public func seqRightValidationArray<E: Semigroup, A, B>(
    _ lhs: Validation<E, [A]>,
    _ rhs: Validation<E, [B]>
) -> Validation<E, [B]> {
    Validation.liftA2({ (a: [A], b: [B]) in a.seqRight(b) })(lhs, rhs)
}

public func seqLeftValidationArray<E: Semigroup, A, B>(
    _ lhs: Validation<E, [A]>,
    _ rhs: Validation<E, [B]>
) -> Validation<E, [A]> {
    Validation.liftA2({ (a: [A], b: [B]) in a.seqLeft(b) })(lhs, rhs)
}
