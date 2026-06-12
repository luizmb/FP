// join :: Monad m => m (m a) -> m a
// Top-level free function versions of the static join/void methods.

// These free functions provide a uniform, point-free way to flatten nested
// monadic structures. They delegate to the static `join`/`void` methods on
// each type. Available overloads:
//
//   join([[ A ]])               -> [A]                   (Array)
//   join(A??)                   -> A?                    (Optional)
//   join(Result<Result<A,E>,E>) -> Result<A, E>          (Result)
//
//   void([A])                   -> [Void]
//   void(A?)                    -> Void?
//   void(Result<A,E>)           -> Result<Void, E>

// MARK: - Array

/// Flattens a nested array into a single flat array.
/// - SeeAlso: ``Array/join(_:)``
public func join<A>(_ nested: [[A]]) -> [A] {
    Array.join(nested)
}

/// Discards all values in an array, keeping the structure.
public func void<A>(_ fa: [A]) -> [Void] {
    fa.void()
}

// MARK: - Optional

public func join<A>(_ nested: A??) -> A? {
    nested.flatMap(CoreFP.id)
}

public func void<A>(_ fa: A?) -> Void? {
    fa.void()
}

// MARK: - Result

public func join<A, E: Error>(_ nested: Result<Result<A, E>, E>) -> Result<A, E> {
    nested.flatMap(CoreFP.id)
}

public func void<A, E: Error>(_ fa: Result<A, E>) -> Result<Void, E> {
    fa.void()
}

