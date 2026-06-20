// SPDX-License-Identifier: Apache-2.0
import CoreFP
import CoreFPOperators
import DataStructure

/// (<£^>) :: (a -> b) -> Stateful<s, Validation<e, a>> -> Stateful<s, Validation<e, b>>
public func <£^> <S, E: Semigroup, A, B>(
    _ fn: @escaping @Sendable (A) -> B,
    _ stateful: Stateful<S, Validation<E, A>>
) -> Stateful<S, Validation<E, B>> {
    fmapTStatefulValidation(fn)(stateful)
}

/// (<&^>) :: Stateful<s, Validation<e, a>> -> (a -> b) -> Stateful<s, Validation<e, b>>
public func <&^> <S, E: Semigroup, A, B>(
    _ stateful: Stateful<S, Validation<E, A>>,
    _ fn: @escaping @Sendable (A) -> B
) -> Stateful<S, Validation<E, B>> {
    fmapTStatefulValidation(fn)(stateful)
}
