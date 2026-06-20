// SPDX-License-Identifier: Apache-2.0
import Foundation

// EitherTOptional: outer = Either, inner = Optional
// Type: Either<L, A?> = Either<L, Optional<A>>

/// mapT for Either<L, A?> — maps the inner Optional's value
/// fmap :: (a -> b) -> Either<l, a?> -> Either<l, b?>
public func mapTEitherOptional<L, A, B>(
    _ fn: @escaping @Sendable (A) -> B,
    _ either: Either<L, A?>
) -> Either<L, B?> {
    either.mapRight { optA in optA.map(fn) }
}

/// Curried fmapT
public func fmapTEitherOptional<L, A, B>(
    _ fn: @escaping @Sendable (A) -> B
) -> (Either<L, A?>) -> Either<L, B?> {
    { either in mapTEitherOptional(fn, either) }
}
