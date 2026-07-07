// SPDX-License-Identifier: Apache-2.0
import CoreFP
import CoreFPOperators
import DataStructure

/// (<£^>) :: (a -> b) -> Validation<e, [a]> -> Validation<e, [b]>
public func <£^> <E: Semigroup, A, B>(_ fn: @escaping @Sendable (A) -> B, _ v: Validation<E, [A]>) -> Validation<E, [B]> {
    mapTValidationArray(fn)(v)
}

/// (<&^>) :: Validation<e, [a]> -> (a -> b) -> Validation<e, [b]>
public func <&^> <E: Semigroup, A, B>(_ v: Validation<E, [A]>, _ fn: @escaping @Sendable (A) -> B) -> Validation<E, [B]> {
    mapTValidationArray(fn)(v)
}
