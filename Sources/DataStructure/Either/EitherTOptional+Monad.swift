// SPDX-License-Identifier: Apache-2.0
import Foundation

// EitherTOptional: outer = Either, inner = Optional
// Type: Either<L, A?> = Either<L, Optional<A>>
// Haskell: MaybeT (Either L)

/// flatMapT for Either<L, A?>
/// .left(l)      → .left(l)
/// .right(.none) → .right(.none)
/// .right(.some(a)) → fn(a)
public func flatMapTEitherOptional<L, A, B>(
    _ either: Either<L, A?>,
    _ fn: @escaping @Sendable (A) -> Either<L, B?>
) -> Either<L, B?> {
    either.flatMap { optA in
        optA.map(fn) ?? .right(.none)
    }
}

/// Curried version
public func bindTEitherOptional<L, A, B>(
    _ fn: @escaping @Sendable (A) -> Either<L, B?>
) -> (Either<L, A?>) -> Either<L, B?> {
    { either in flatMapTEitherOptional(either, fn) }
}

/// Kleisli composition for `EitherT + Optional` (left-to-right)
/// (>=>) :: (a -> Either<l,b?>) -> (b -> Either<l,c?>) -> a -> Either<l,c?>
public func kleisliT<L, A, B, C>(
    _ fn1: @escaping @Sendable (A) -> Either<L, B?>,
    _ fn2: @escaping @Sendable (B) -> Either<L, C?>
) -> (A) -> Either<L, C?> {
    { a in flatMapTEitherOptional(fn1(a), fn2) }
}
