/// Sequence a list of results
/// sequence :: [Result<a, e>] -> Result<[a], e>
public func sequence<A, E>(_ results: [Result<A, E>]) -> Result<[A], E> {
    results.traverse(CoreFP.id)
}

/// Map and sequence for Result
/// traverse :: (a -> Result<b, e>) -> [a] -> Result<[b], e>
public func traverse<A, B, E>(_ fn: @escaping @Sendable (A) -> Result<B, E>) -> ([A]) -> Result<[B], E> {
    { array in
        array.traverse(fn)
    }
}
