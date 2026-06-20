// SPDX-License-Identifier: Apache-2.0
import CoreFP
import CoreFPOperators
import DataStructure

/// (<£>) :: (a -> b) -> Validation<e, a> -> Validation<e, b>
public func <£> <E: Semigroup, A: Sendable, B: Sendable>(_ fn: @escaping @Sendable (A) -> B, _ v: Validation<E, A>) -> Validation<E, B> {
    v.mapSuccess(fn)
}

/// (<&>) :: Validation<e, a> -> (a -> b) -> Validation<e, b>
public func <&> <E: Semigroup, A: Sendable, B: Sendable>(_ v: Validation<E, A>, _ fn: @escaping @Sendable (A) -> B) -> Validation<E, B> {
    v.mapSuccess(fn)
}

/// (£>) :: Validation<e, a> -> b -> Validation<e, b>
public func £> <E: Semigroup, A: Sendable, B: Sendable>(_ v: Validation<E, A>, _ value: B) -> Validation<E, B> {
    v.mapSuccess(const(value))
}

/// (<£) :: b -> Validation<e, a> -> Validation<e, b>
public func <£ <E: Semigroup, A: Sendable, B: Sendable>(_ value: B, _ v: Validation<E, A>) -> Validation<E, B> {
    v £> value
}
