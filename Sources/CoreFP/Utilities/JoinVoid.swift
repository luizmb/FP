// join :: Monad m => m (m a) -> m a
// Top-level free function versions of the static join/void methods.

// These free functions provide a uniform, point-free way to flatten nested
// monadic structures. They delegate to the static `join`/`void` methods on
// each type. Available overloads:
//
//   join([[ A ]])               -> [A]                   (Array)
//   join(A??)                   -> A?                    (Optional)
//   join(Result<Result<A,E>,E>) -> Result<A, E>          (Result)
//   join(DeferredTask<DeferredTask<A>>) -> DeferredTask<A>
//   join(DeferredStream<DeferredStream<A>>) -> DeferredStream<A>
//
//   void([A])                   -> [Void]
//   void(A?)                    -> Void?
//   void(Result<A,E>)           -> Result<Void, E>
//   void(DeferredTask<A>)       -> DeferredTask<Void>
//   void(DeferredStream<A>)     -> DeferredStream<Void>

// MARK: - Array

public func join<A>(_ nested: [[A]]) -> [A] {
    Array.join(nested)
}

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

// MARK: - DeferredTask

public func join<A: Sendable>(_ nested: DeferredTask<DeferredTask<A>>) -> DeferredTask<A> {
    DeferredTask.join(nested)
}

public func void<A: Sendable>(_ fa: DeferredTask<A>) -> DeferredTask<Void> {
    fa.void()
}

// MARK: - DeferredStream

public func join<A: Sendable>(_ nested: DeferredStream<DeferredStream<A>>) -> DeferredStream<A> {
    DeferredStream.join(nested)
}

public func void<A: Sendable>(_ fa: DeferredStream<A>) -> DeferredStream<Void> {
    fa.void()
}
