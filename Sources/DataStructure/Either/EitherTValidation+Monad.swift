// SPDX-License-Identifier: Apache-2.0
import CoreFP

/// EitherTValidation: outer = Either, inner = Validation
/// Type: Either<L, Validation<E, A>>
/// flatMapT sequences through Validation — short-circuits on failure (does NOT accumulate).

public func flatMapTEitherValidation<L, E: Semigroup, A, B>(
    _ either: Either<L, Validation<E, A>>,
    _ fn: @escaping @Sendable (A) -> Either<L, Validation<E, B>>
) -> Either<L, Validation<E, B>> {
    either.flatMap { validation in
        validation.match(
            caseFailure: { e in .right(.failure(e)) },
            caseSuccess: fn
        )
    }
}

/// `bindTEitherValidation`.
public func bindTEitherValidation<L, E: Semigroup, A, B>(
    _ fn: @escaping @Sendable (A) -> Either<L, Validation<E, B>>
) -> (Either<L, Validation<E, A>>) -> Either<L, Validation<E, B>> {
    { flatMapTEitherValidation($0, fn) }
}
