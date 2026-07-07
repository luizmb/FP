// SPDX-License-Identifier: Apache-2.0
import CoreFPOperators
import DataStructure

// EitherTArray: outer = Either, inner = Array
// Type: Either<L, [A]>

/// (>>-) :: Either<l,[a]> -> (a -> Either<l,[b]>) -> Either<l,[b]>
public func >>- <L: Sendable, A: Sendable, B: Sendable>(
    _ either: Either<L, [A]>,
    _ fn: @escaping @Sendable (A) -> Either<L, [B]>
) -> Either<L, [B]> {
    flatMapTEitherArray(either, fn)
}

/// (-<<) :: (a -> Either<l,[b]>) -> Either<l,[a]> -> Either<l,[b]>
public func -<< <L: Sendable, A: Sendable, B: Sendable>(
    _ fn: @escaping @Sendable (A) -> Either<L, [B]>,
    _ either: Either<L, [A]>
) -> Either<L, [B]> {
    flatMapTEitherArray(either, fn)
}

/// (>=>) :: (a -> Either<l,[b]>) -> (b -> Either<l,[c]>) -> a -> Either<l,[c]>
public func >=> <L: Sendable, A: Sendable, B: Sendable, C: Sendable>(
    _ fn1: @escaping @Sendable (A) -> Either<L, [B]>,
    _ fn2: @escaping @Sendable (B) -> Either<L, [C]>
) -> (A) -> Either<L, [C]> {
    kleisliT(fn1, fn2)
}
