// SPDX-License-Identifier: Apache-2.0
import CoreFP

/// Sequence a Result of a Validation-producing computation into a Validation of a Result.
/// sequence :: Result<Validation<e2, c>, e> -> Validation<e2, Result<c, e>>
public func sequence<E2: Semigroup, C, E>(_ result: Result<Validation<E2, C>, E>) -> Validation<E2, Result<C, E>> {
    result.traverse(CoreFP.id)
}

/// Map and sequence over the Success value of a Result, collecting into a Validation.
/// traverse :: (a -> Validation<e2, c>) -> Result<a, e> -> Validation<e2, Result<c, e>>
public func traverse<A, E2: Semigroup, C, E>(
    _ fn: @escaping @Sendable (A) -> Validation<E2, C>
) -> @Sendable (Result<A, E>) -> Validation<E2, Result<C, E>> {
    { result in
        result.traverse(fn)
    }
}
