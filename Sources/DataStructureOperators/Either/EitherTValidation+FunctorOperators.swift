import DataStructure
import CoreFPOperators
import CoreFP

// (<£^>) :: (a -> b) -> Either<l, Validation<e, a>> -> Either<l, Validation<e, b>>
public func <£^> <L, E: Semigroup, A, B>(_ fn: @escaping (A) -> B, _ either: Either<L, Validation<E, A>>) -> Either<L, Validation<E, B>> {
    fmapTEitherValidation(fn)(either)
}

// (<&^>) :: Either<l, Validation<e, a>> -> (a -> b) -> Either<l, Validation<e, b>>
public func <&^> <L, E: Semigroup, A, B>(_ either: Either<L, Validation<E, A>>, _ fn: @escaping (A) -> B) -> Either<L, Validation<E, B>> {
    fmapTEitherValidation(fn)(either)
}
