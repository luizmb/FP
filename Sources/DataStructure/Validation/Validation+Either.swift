// SPDX-License-Identifier: Apache-2.0
import CoreFP

public extension Validation {
    /// Convert to Either — failure maps to left, success maps to right.
    func toEither() -> Either<E, A> {
        match(caseFailure: Either.left, caseSuccess: Either.right)
    }
}

public extension Validation {
    /// Convert from Either — left maps to failure, right maps to success.
    ///
    /// ```swift
    /// Validation(Either<[String], Int>.right(42))     // .success(42)
    /// Validation(Either<[String], Int>.left(["bad"])) // .failure(["bad"])
    /// ```
    init(_ either: Either<E, A>) {
        self = either.match(caseLeft: Validation.failure, caseRight: Validation.success)
    }
}

public extension Either where A: Semigroup {
    /// Convert to Validation — left maps to failure, right maps to success. Requires a `Semigroup` left side,
    /// so the resulting `Validation` can accumulate errors.
    func toValidation() -> Validation<A, B> {
        Validation(self)
    }
}
