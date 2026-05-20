import CoreFP

// ValidationTEither: outer = Validation, inner = Either
// Type: Validation<E, Either<L, A>>

public func fmapTValidationEither<E: Semigroup, L, A, B>(
    _ fn: @escaping @Sendable (A) -> B
) -> (Validation<E, Either<L, A>>) -> Validation<E, Either<L, B>> {
    { $0.mapSuccess(Either<L, A>.fmap(fn)) }
}
