// SPDX-License-Identifier: Apache-2.0
import CoreFPOperators
import DataStructure

// MARK: - Transformer functor operators: NonEmpty<A?> and NonEmpty<A>?

/// (<£^>) :: (A -> B) -> NonEmpty<A?> -> NonEmpty<B?>
public func <£^> <A, B>(
    _ fn: @escaping @Sendable (A) -> B,
    _ ne: NonEmpty<A?>
) -> NonEmpty<B?> {
    ne.mapT(fn)
}

/// (<&^>) :: NonEmpty<A?> -> (A -> B) -> NonEmpty<B?>
public func <&^> <A, B>(
    _ ne: NonEmpty<A?>,
    _ fn: @escaping @Sendable (A) -> B
) -> NonEmpty<B?> {
    ne.mapT(fn)
}
