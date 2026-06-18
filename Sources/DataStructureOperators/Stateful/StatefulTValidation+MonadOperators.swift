// SPDX-License-Identifier: Apache-2.0
import CoreFP
import CoreFPOperators
import DataStructure

/// (>>-) :: Stateful<s, Validation<e, a>> -> (a -> Stateful<s, Validation<e, b>>) -> Stateful<s, Validation<e, b>>
public func >>- <S, E: Semigroup, A, B>(
    _ stateful: Stateful<S, Validation<E, A>>,
    _ fn: @escaping @Sendable (A) -> Stateful<S, Validation<E, B>>
) -> Stateful<S, Validation<E, B>> {
    flatMapTStatefulValidation(stateful, fn)
}

/// (-<<) :: (a -> Stateful<s, Validation<e, b>>) -> Stateful<s, Validation<e, a>> -> Stateful<s, Validation<e, b>>
public func -<< <S, E: Semigroup, A, B>(
    _ fn: @escaping @Sendable (A) -> Stateful<S, Validation<E, B>>,
    _ stateful: Stateful<S, Validation<E, A>>
) -> Stateful<S, Validation<E, B>> {
    flatMapTStatefulValidation(stateful, fn)
}

/// (>=>) :: (a -> Stateful<s, Validation<e,b>>) -> (b -> Stateful<s, Validation<e,c>>) -> a -> Stateful<s, Validation<e,c>>
public func >=> <S, E: Semigroup, A, B, C>(
    _ fn1: @escaping @Sendable (A) -> Stateful<S, Validation<E, B>>,
    _ fn2: @escaping @Sendable (B) -> Stateful<S, Validation<E, C>>
) -> (A) -> Stateful<S, Validation<E, C>> {
    { a in flatMapTStatefulValidation(fn1(a), fn2) }
}
