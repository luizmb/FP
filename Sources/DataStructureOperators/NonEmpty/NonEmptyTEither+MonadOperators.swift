// SPDX-License-Identifier: Apache-2.0
import CoreFPOperators
import DataStructure

// NonEmptyTEither: outer = NonEmpty, inner = Either
// Type: NonEmpty<Either<L, A>>

/// (>>-) :: NonEmpty<Either<L, A>> -> (A -> NonEmpty<Either<L, B>>) -> NonEmpty<Either<L, B>>
public func >>- <L, A, B>(
    _ ne: NonEmpty<Either<L, A>>,
    _ fn: @escaping @Sendable (A) -> NonEmpty<Either<L, B>>
) -> NonEmpty<Either<L, B>> {
    ne.flatMapT(fn)
}

/// (-<<) :: (A -> NonEmpty<Either<L, B>>) -> NonEmpty<Either<L, A>> -> NonEmpty<Either<L, B>>
public func -<< <L, A, B>(
    _ fn: @escaping @Sendable (A) -> NonEmpty<Either<L, B>>,
    _ ne: NonEmpty<Either<L, A>>
) -> NonEmpty<Either<L, B>> {
    ne.flatMapT(fn)
}

/// (>=>) :: (A0 -> NonEmpty<Either<L, A>>) -> (A -> NonEmpty<Either<L, B>>) -> A0 -> NonEmpty<Either<L, B>>
public func >=> <L, A0, A, B>(
    _ fn1: @escaping @Sendable (A0) -> NonEmpty<Either<L, A>>,
    _ fn2: @escaping @Sendable (A) -> NonEmpty<Either<L, B>>
) -> (A0) -> NonEmpty<Either<L, B>> {
    kleisliT(fn1, fn2)
}

/// (<=<) :: (A -> NonEmpty<Either<L, B>>) -> (A0 -> NonEmpty<Either<L, A>>) -> A0 -> NonEmpty<Either<L, B>>
public func <=< <L, A0, A, B>(
    _ fn2: @escaping @Sendable (A) -> NonEmpty<Either<L, B>>,
    _ fn1: @escaping @Sendable (A0) -> NonEmpty<Either<L, A>>
) -> (A0) -> NonEmpty<Either<L, B>> {
    fn1 >=> fn2
}
