// SPDX-License-Identifier: Apache-2.0
import CoreFPOperators
import DataStructure

// MARK: - Transformer monad operators: NonEmpty<Result<A, E>>

/// (>>-) :: NonEmpty<Result<a,e>> -> (a -> NonEmpty<Result<b,e>>) -> NonEmpty<Result<b,e>>
public func >>- <A, B, E>(
    _ ne: NonEmpty<Result<A, E>>,
    _ fn: @escaping @Sendable (A) -> NonEmpty<Result<B, E>>
) -> NonEmpty<Result<B, E>> {
    ne.flatMapT(fn)
}

/// (-<<) :: (a -> NonEmpty<Result<b,e>>) -> NonEmpty<Result<a,e>> -> NonEmpty<Result<b,e>>
public func -<< <A, B, E>(
    _ fn: @escaping @Sendable (A) -> NonEmpty<Result<B, E>>,
    _ ne: NonEmpty<Result<A, E>>
) -> NonEmpty<Result<B, E>> {
    ne.flatMapT(fn)
}

/// (>=>) :: (a -> NonEmpty<Result<b,e>>) -> (b -> NonEmpty<Result<c,e>>) -> a -> NonEmpty<Result<c,e>>
public func >=> <A, B, C, E>(
    _ fn1: @escaping @Sendable (A) -> NonEmpty<Result<B, E>>,
    _ fn2: @escaping @Sendable (B) -> NonEmpty<Result<C, E>>
) -> (A) -> NonEmpty<Result<C, E>> {
    kleisliT(fn1, fn2)
}
