// SPDX-License-Identifier: Apache-2.0
import CoreFPOperators
import DataStructure

/// (<*>) :: Stateful<s, NonEmpty<(a -> b)>> -> Stateful<s, NonEmpty<a>> -> Stateful<s, NonEmpty<b>>
public func <*> <S, A, B>(
    _ sf: Stateful<S, NonEmpty<@Sendable (A) -> B>>,
    _ sa: Stateful<S, NonEmpty<A>>
) -> Stateful<S, NonEmpty<B>> {
    applyStatefulNonEmpty(sf, sa)
}

/// (*>) :: Stateful<s, NonEmpty<a>> -> Stateful<s, NonEmpty<b>> -> Stateful<s, NonEmpty<b>>
public func *> <S, A, B>(_ lhs: Stateful<S, NonEmpty<A>>, _ rhs: Stateful<S, NonEmpty<B>>) -> Stateful<S, NonEmpty<B>> {
    seqRightStatefulNonEmpty(lhs, rhs)
}

/// (<*) :: Stateful<s, NonEmpty<a>> -> Stateful<s, NonEmpty<b>> -> Stateful<s, NonEmpty<a>>
public func <* <S, A, B>(_ lhs: Stateful<S, NonEmpty<A>>, _ rhs: Stateful<S, NonEmpty<B>>) -> Stateful<S, NonEmpty<A>> {
    seqLeftStatefulNonEmpty(lhs, rhs)
}
