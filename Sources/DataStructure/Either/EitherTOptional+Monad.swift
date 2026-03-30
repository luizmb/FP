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
    _ fn: @escaping (A) -> Either<L, B?>
) -> Either<L, B?> {
    either.flatMap { optA in
        optA.map(fn) ?? .right(.none)
    }
}

/// Curried version
public func bindTEitherOptional<L, A, B>(
    _ fn: @escaping (A) -> Either<L, B?>
) -> (Either<L, A?>) -> Either<L, B?> {
    { either in flatMapTEitherOptional(either, fn) }
}
