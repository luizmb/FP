import CoreFP
import DataStructure

/// Sequence a Validation of an Optional into an Optional of Validation.
/// sequence :: Validation e b? -> Validation e b?
public func sequence<E: Semigroup, B>(_ validation: Validation<E, B?>) -> Validation<E, B>? {
    validation.traverse(CoreFP.id)
}

/// Map and sequence over the success side of a Validation, collecting into Optional.
/// traverse :: (a -> b?) -> Validation e a -> Validation e b?
public func traverse<E: Semigroup, A, B>(_ fn: @escaping (A) -> B?) -> (Validation<E, A>) -> Validation<E, B>? {
    { validation in validation.traverse(fn) }
}
