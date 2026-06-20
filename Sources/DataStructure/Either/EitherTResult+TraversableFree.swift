// SPDX-License-Identifier: Apache-2.0
import CoreFP

/// Sequence an Either of a Result into a Result of Either.
/// sequence :: Either a (Result<c, e>) -> Result<Either a c, e>
public func sequence<A, C, E>(_ either: Either<A, Result<C, E>>) -> Result<Either<A, C>, E> {
    either.traverse(CoreFP.id)
}

/// Map and sequence over the right side of an Either, collecting into Result.
/// traverse :: (b -> Result<c, e>) -> Either a b -> Result<Either a c, e>
public func traverse<A, B, C, E>(_ fn: @escaping @Sendable (B) -> Result<C, E>) -> @Sendable (Either<A, B>) -> Result<Either<A, C>, E> {
    { either in either.traverse(fn) }
}
