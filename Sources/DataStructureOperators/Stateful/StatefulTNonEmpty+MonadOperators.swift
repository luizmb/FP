// SPDX-License-Identifier: Apache-2.0
import CoreFPOperators
import DataStructure

/// (>>-) :: Stateful<s, NonEmpty<a>> -> (a -> Stateful<s, NonEmpty<b>?>) -> Stateful<s, NonEmpty<b>?>
public func >>- <S, A, B>(
    _ stateful: Stateful<S, NonEmpty<A>>,
    _ fn: @escaping @Sendable (A) -> Stateful<S, NonEmpty<B>?>
) -> Stateful<S, NonEmpty<B>?> {
    stateful.flatMapT(fn)
}

/// (-<<) :: (a -> Stateful<s, NonEmpty<b>?>) -> Stateful<s, NonEmpty<a>> -> Stateful<s, NonEmpty<b>?>
public func -<< <S, A, B>(
    _ fn: @escaping @Sendable (A) -> Stateful<S, NonEmpty<B>?>,
    _ stateful: Stateful<S, NonEmpty<A>>
) -> Stateful<S, NonEmpty<B>?> {
    stateful.flatMapT(fn)
}

/// (>=>) :: (a -> Stateful<s, NonEmpty<b>?>) -> (b -> Stateful<s, NonEmpty<c>?>) -> a -> Stateful<s, NonEmpty<c>?>
public func >=> <S, A: Sendable, B: Sendable, C>(
    _ fn1: @escaping @Sendable (A) -> Stateful<S, NonEmpty<B>?>,
    _ fn2: @escaping @Sendable (B) -> Stateful<S, NonEmpty<C>?>
) -> (A) -> Stateful<S, NonEmpty<C>?> {
    kleisliT(fn1, fn2)
}
