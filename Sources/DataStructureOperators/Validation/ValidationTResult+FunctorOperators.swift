// SPDX-License-Identifier: Apache-2.0
import CoreFP
import CoreFPOperators
import DataStructure

/// (<£^>) :: (a -> b) -> Validation<e, Result<a, err>> -> Validation<e, Result<b, err>>
public func <£^> <E: Semigroup, A, B, Err: Error>(
    _ fn: @escaping @Sendable (A) -> B,
    _ v: Validation<E, Result<A, Err>>
) -> Validation<E, Result<B, Err>> {
    mapTValidationResult(fn)(v)
}

/// (<&^>) :: Validation<e, Result<a, err>> -> (a -> b) -> Validation<e, Result<b, err>>
public func <&^> <E: Semigroup, A, B, Err: Error>(
    _ v: Validation<E, Result<A, Err>>,
    _ fn: @escaping @Sendable (A) -> B
) -> Validation<E, Result<B, Err>> {
    mapTValidationResult(fn)(v)
}
