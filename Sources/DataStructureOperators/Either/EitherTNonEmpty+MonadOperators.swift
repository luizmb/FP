// SPDX-License-Identifier: Apache-2.0
import CoreFPOperators
import DataStructure

// EitherTNonEmpty: outer = Either, inner = NonEmpty
// Type: Either<L, NonEmpty<A>>

/// (>>-) :: Either<l, NonEmpty<a>> -> (a -> Either<l, NonEmpty<b>?>) -> Either<l, NonEmpty<b>?>
public func >>- <L, A, B>(
    _ either: Either<L, NonEmpty<A>>,
    _ fn: @escaping @Sendable (A) -> Either<L, NonEmpty<B>?>
) -> Either<L, NonEmpty<B>?> {
    flatMapTEitherNonEmpty(either, fn)
}

/// (-<<) :: (a -> Either<l, NonEmpty<b>?>) -> Either<l, NonEmpty<a>> -> Either<l, NonEmpty<b>?>
public func -<< <L, A, B>(
    _ fn: @escaping @Sendable (A) -> Either<L, NonEmpty<B>?>,
    _ either: Either<L, NonEmpty<A>>
) -> Either<L, NonEmpty<B>?> {
    flatMapTEitherNonEmpty(either, fn)
}

/// (>=>) :: (a -> Either<l, NonEmpty<b>?>) -> (b -> Either<l, NonEmpty<c>?>) -> a -> Either<l, NonEmpty<c>?>
public func >=> <L, A, B, C>(
    _ fn1: @escaping @Sendable (A) -> Either<L, NonEmpty<B>?>,
    _ fn2: @escaping @Sendable (B) -> Either<L, NonEmpty<C>?>
) -> (A) -> Either<L, NonEmpty<C>?> {
    kleisliT(fn1, fn2)
}
