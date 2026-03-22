import CoreFP

public extension Validation {
    /// Convert to Either — failure maps to left, success maps to right.
    func toEither() -> Either<E, A> {
        match(caseFailure: Either.left, caseSuccess: Either.right)
    }
}

/// Convert from Either to Validation — requires E: Semigroup.
public func validationFromEither<E: Semigroup, A>(_ either: Either<E, A>) -> Validation<E, A> {
    either.match(caseLeft: Validation.failure, caseRight: Validation.success)
}
