// SPDX-License-Identifier: Apache-2.0
import CoreFP
import CoreFPOperators
import DataStructure

/// (<£^>) :: (a -> b) -> Validation<e, Reader<env, a>> -> Validation<e, Reader<env, b>>
public func <£^> <E: Semigroup, Env, A, B>(
    _ fn: @escaping @Sendable (A) -> B,
    _ v: Validation<E, Reader<Env, A>>
) -> Validation<E, Reader<Env, B>> {
    fmapTValidationReader(fn)(v)
}

/// (<&^>) :: Validation<e, Reader<env, a>> -> (a -> b) -> Validation<e, Reader<env, b>>
public func <&^> <E: Semigroup, Env, A, B>(
    _ v: Validation<E, Reader<Env, A>>,
    _ fn: @escaping @Sendable (A) -> B) -> Validation<E, Reader<Env, B>> {
    fmapTValidationReader(fn)(v)
}
