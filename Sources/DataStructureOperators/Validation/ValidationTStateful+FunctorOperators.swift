// SPDX-License-Identifier: Apache-2.0
import CoreFP
import CoreFPOperators
import DataStructure

/// (<£^>) :: (a -> b) -> Validation<e, Stateful<s, a>> -> Validation<e, Stateful<s, b>>
public func <£^> <E: Semigroup, S, A, B>(
    _ fn: @escaping @Sendable (A) -> B,
    _ v: Validation<E, Stateful<S, A>>
) -> Validation<E, Stateful<S, B>> {
    fmapTValidationStateful(fn)(v)
}

/// (<&^>) :: Validation<e, Stateful<s, a>> -> (a -> b) -> Validation<e, Stateful<s, b>>
public func <&^> <E: Semigroup, S, A, B>(
    _ v: Validation<E, Stateful<S, A>>,
    _ fn: @escaping @Sendable (A) -> B
) -> Validation<E, Stateful<S, B>> {
    fmapTValidationStateful(fn)(v)
}
