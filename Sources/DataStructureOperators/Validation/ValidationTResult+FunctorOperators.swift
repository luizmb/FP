import DataStructure
import CoreFPOperators
import CoreFP

// (<£^>) :: (a -> b) -> Validation<e, Result<a, err>> -> Validation<e, Result<b, err>>
public func <£^> <E: Semigroup, A, B, Err: Error>(_ fn: @escaping (A) -> B, _ v: Validation<E, Result<A, Err>>) -> Validation<E, Result<B, Err>> {
    fmapTValidationResult(fn)(v)
}

// (<&^>) :: Validation<e, Result<a, err>> -> (a -> b) -> Validation<e, Result<b, err>>
public func <&^> <E: Semigroup, A, B, Err: Error>(_ v: Validation<E, Result<A, Err>>, _ fn: @escaping (A) -> B) -> Validation<E, Result<B, Err>> {
    fmapTValidationResult(fn)(v)
}
