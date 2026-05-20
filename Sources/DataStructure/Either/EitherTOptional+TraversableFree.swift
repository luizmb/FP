import CoreFP
import DataStructure

/// Sequence an Either of an Optional into an Optional of Either.
/// sequence :: Either a c? -> Either a c?
public func sequence<A, C>(_ either: Either<A, C?>) -> Either<A, C>? {
    either.traverse(CoreFP.id)
}

/// Map and sequence over the right side of an Either, collecting into Optional.
/// traverse :: (b -> c?) -> Either a b -> Either a c?
public func traverse<A, B, C>(_ fn: @escaping @Sendable (B) -> C?) -> (Either<A, B>) -> Either<A, C>? {
    { either in either.traverse(fn) }
}
