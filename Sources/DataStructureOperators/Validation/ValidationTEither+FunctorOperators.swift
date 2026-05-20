import CoreFP
import CoreFPOperators
import DataStructure

// (<£^>) :: (a -> b) -> Validation<e, Either<l, a>> -> Validation<e, Either<l, b>>
public func <£^> <E: Semigroup, L, A, B>(_ fn: @escaping @Sendable (A) -> B, _ v: Validation<E, Either<L, A>>) -> Validation<E, Either<L, B>> {
    fmapTValidationEither(fn)(v)
}

// (<&^>) :: Validation<e, Either<l, a>> -> (a -> b) -> Validation<e, Either<l, b>>
public func <&^> <E: Semigroup, L, A, B>(_ v: Validation<E, Either<L, A>>, _ fn: @escaping @Sendable (A) -> B) -> Validation<E, Either<L, B>> {
    fmapTValidationEither(fn)(v)
}
