import DataStructure
import CoreFPOperators
import CoreFP

// (<£^>) :: (a -> b) -> Validation<e, Either<l, a>> -> Validation<e, Either<l, b>>
public func <£^> <E: Semigroup, L, A, B>(_ fn: @escaping (A) -> B, _ v: Validation<E, Either<L, A>>) -> Validation<E, Either<L, B>> {
    fmapTValidationEither(fn)(v)
}

// (<&^>) :: Validation<e, Either<l, a>> -> (a -> b) -> Validation<e, Either<l, b>>
public func <&^> <E: Semigroup, L, A, B>(_ v: Validation<E, Either<L, A>>, _ fn: @escaping (A) -> B) -> Validation<E, Either<L, B>> {
    fmapTValidationEither(fn)(v)
}
