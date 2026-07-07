// SPDX-License-Identifier: Apache-2.0
import CoreFP

/// Sequence a Result of an Either-producing computation into an Either of a Result.
/// sequence :: Result<Either<l, c>, e> -> Either<l, Result<c, e>>
public func sequence<L, C, E>(_ result: Result<Either<L, C>, E>) -> Either<L, Result<C, E>> {
    result.traverse(CoreFP.id)
}

/// Map and sequence over the Success value of a Result, collecting into an Either.
/// traverse :: (a -> Either<l, c>) -> Result<a, e> -> Either<l, Result<c, e>>
public func traverse<A, L, C, E>(
    _ fn: @escaping @Sendable (A) -> Either<L, C>
) -> @Sendable (Result<A, E>) -> Either<L, Result<C, E>> {
    { result in
        result.traverse(fn)
    }
}
