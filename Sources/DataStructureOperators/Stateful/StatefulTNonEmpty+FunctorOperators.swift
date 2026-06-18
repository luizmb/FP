// SPDX-License-Identifier: Apache-2.0
import CoreFPOperators
import DataStructure

// StatefulTNonEmpty: outer = Stateful, inner = NonEmpty
// Type: Stateful<S, NonEmpty<A>>

/// (<£^>) :: (A -> B) -> Stateful<S, NonEmpty<A>> -> Stateful<S, NonEmpty<B>>
public func <£^> <S, A, B>(_ fn: @escaping @Sendable (A) -> B, _ stateful: Stateful<S, NonEmpty<A>>) -> Stateful<S, NonEmpty<B>> {
    stateful.mapT(fn)
}

/// (<&^>) :: Stateful<S, NonEmpty<A>> -> (A -> B) -> Stateful<S, NonEmpty<B>>
public func <&^> <S, A, B>(_ stateful: Stateful<S, NonEmpty<A>>, _ fn: @escaping @Sendable (A) -> B) -> Stateful<S, NonEmpty<B>> {
    stateful.mapT(fn)
}
