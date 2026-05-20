import CoreFP

// ValidationTResult: outer = Validation, inner = Result
// Type: Validation<E, Result<A, Err>>

public func applyValidationResult<E: Semigroup, A, B, Err: Error>(
    _ vf: Validation<E, Result<@Sendable (A) -> B, Err>>,
    _ va: Validation<E, Result<A, Err>>
) -> Validation<E, Result<B, Err>> {
    Validation.liftA2(Result.apply)(vf, va)
}

public func liftA2ValidationResult<E: Semigroup, A, B, C, Err: Error>(
    _ fn: @escaping @Sendable (A, B) -> C
) -> (Validation<E, Result<A, Err>>, Validation<E, Result<B, Err>>) -> Validation<E, Result<C, Err>> {
    Validation.liftA2(Result.liftA2(fn))
}

public func seqRightValidationResult<E: Semigroup, A, B, Err: Error>(
    _ lhs: Validation<E, Result<A, Err>>,
    _ rhs: Validation<E, Result<B, Err>>
) -> Validation<E, Result<B, Err>> {
    Validation.liftA2({ (a: Result<A, Err>, b: Result<B, Err>) in a.seqRight(b) })(lhs, rhs)
}

public func seqLeftValidationResult<E: Semigroup, A, B, Err: Error>(
    _ lhs: Validation<E, Result<A, Err>>,
    _ rhs: Validation<E, Result<B, Err>>
) -> Validation<E, Result<A, Err>> {
    Validation.liftA2({ (a: Result<A, Err>, b: Result<B, Err>) in a.seqLeft(b) })(lhs, rhs)
}
