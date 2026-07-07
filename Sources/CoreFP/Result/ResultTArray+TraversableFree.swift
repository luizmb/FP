// SPDX-License-Identifier: Apache-2.0
/// Sequence a Result of an array-producing computation into a list of Results.
/// sequence :: Result<[a], e> -> [Result<a, e>]
public func sequence<A, E>(_ result: Result<[A], E>) -> [Result<A, E>] {
    result.traverse(CoreFP.id)
}

/// Map and sequence over the Success value of a Result, collecting into an array.
/// traverse :: (a -> [b]) -> Result<a, e> -> [Result<b, e>]
public func traverse<A, B, E>(_ fn: @escaping @Sendable (A) -> [B]) -> @Sendable (Result<A, E>) -> [Result<B, E>] {
    { result in
        result.traverse(fn)
    }
}
