import CoreFP

// EitherTValidation: outer = Either, inner = Validation
// Type: Either<L, Validation<E, A>>

public func fmapTEitherValidation<L, E: Semigroup, A, B>(
    _ fn: @escaping @Sendable (A) -> B,
    _ either: Either<L, Validation<E, A>>
) -> Either<L, Validation<E, B>> {
    either.mapRight(Validation<E, A>.fmap(fn))
}

public func fmapTEitherValidation<L, E: Semigroup, A, B>(
    _ fn: @escaping @Sendable (A) -> B
) -> (Either<L, Validation<E, A>>) -> Either<L, Validation<E, B>> {
    { fmapTEitherValidation(fn, $0) }
}
