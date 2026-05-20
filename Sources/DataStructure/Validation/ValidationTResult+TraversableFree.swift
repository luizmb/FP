import CoreFP
import DataStructure

/// Sequence a Validation of a Result into a Result of Validation.
/// sequence :: Validation e (Result<b, e2>) -> Result<Validation e b, e2>
public func sequence<E: Semigroup, B, E2>(_ validation: Validation<E, Result<B, E2>>) -> Result<Validation<E, B>, E2> {
    validation.traverse(CoreFP.id)
}

/// Map and sequence over the success side of a Validation, collecting into Result.
/// traverse :: (a -> Result<b, e2>) -> Validation e a -> Result<Validation e b, e2>
public func traverse<E: Semigroup, A, B, E2>(
    _ fn: @escaping @Sendable (A) -> Result<B, E2>
) -> (Validation<E, A>) -> Result<Validation<E, B>, E2> {
    { validation in validation.traverse(fn) }
}
