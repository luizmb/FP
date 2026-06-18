// SPDX-License-Identifier: Apache-2.0
import CoreFPOperators
import DataStructure

// EitherTStateful: outer = Either, inner = Stateful
// Type: Either<L, Stateful<S, A>>

/// (>>-) :: Either<l, Stateful<s, a>> -> (a -> Stateful<s, b>) -> Either<l, Stateful<s, b>>
public func >>- <L, S, A, B>(
    _ either: Either<L, Stateful<S, A>>,
    _ fn: @escaping @Sendable (A) -> Stateful<S, B>
) -> Either<L, Stateful<S, B>> {
    either.flatMapT(fn)
}

/// (-<<) :: (a -> Stateful<s, b>) -> Either<l, Stateful<s, a>> -> Either<l, Stateful<s, b>>
public func -<< <L, S, A, B>(
    _ fn: @escaping @Sendable (A) -> Stateful<S, B>,
    _ either: Either<L, Stateful<S, A>>
) -> Either<L, Stateful<S, B>> {
    either.flatMapT(fn)
}

/// (>=>) :: (a -> Either<l, Stateful<s, b>>) -> (b -> Stateful<s, c>) -> a -> Either<l, Stateful<s, c>>
public func >=> <L, S, A, B, C>(
    _ fn1: @escaping @Sendable (A) -> Either<L, Stateful<S, B>>,
    _ fn2: @escaping @Sendable (B) -> Stateful<S, C>
) -> (A) -> Either<L, Stateful<S, C>> {
    { a in fn1(a).flatMapT(fn2) }
}
