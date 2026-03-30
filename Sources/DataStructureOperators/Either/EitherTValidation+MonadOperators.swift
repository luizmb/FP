import CoreFP
import DataStructure
import CoreFPOperators

// (>>-) :: Either<l, Validation<e, a>> -> (a -> Either<l, Validation<e, b>>) -> Either<l, Validation<e, b>>
public func >>- <L, E: Semigroup, A, B>(
    _ either: Either<L, Validation<E, A>>,
    _ fn: @escaping (A) -> Either<L, Validation<E, B>>
) -> Either<L, Validation<E, B>> {
    flatMapTEitherValidation(either, fn)
}

// (-<<) :: (a -> Either<l, Validation<e, b>>) -> Either<l, Validation<e, a>> -> Either<l, Validation<e, b>>
public func -<< <L, E: Semigroup, A, B>(
    _ fn: @escaping (A) -> Either<L, Validation<E, B>>,
    _ either: Either<L, Validation<E, A>>
) -> Either<L, Validation<E, B>> {
    flatMapTEitherValidation(either, fn)
}

// (>=>) :: (a -> Either<l, Validation<e, b>>) -> (b -> Either<l, Validation<e, c>>) -> a -> Either<l, Validation<e, c>>
public func >=> <L, E: Semigroup, A, B, C>(
    _ fn1: @escaping (A) -> Either<L, Validation<E, B>>,
    _ fn2: @escaping (B) -> Either<L, Validation<E, C>>
) -> (A) -> Either<L, Validation<E, C>> {
    { a in flatMapTEitherValidation(fn1(a), fn2) }
}
