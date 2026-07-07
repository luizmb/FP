// SPDX-License-Identifier: Apache-2.0
import CoreFP

// ArrayTResult: outer = Array, inner = Result
// Type: [Result<A,E>] = Array<Result<A,E>>

/// (>>-) :: [Result<a,e>] -> (a -> [Result<b,e>]) -> [Result<b,e>]
public func >>- <A, B, E: Error>(_ arr: [Result<A, E>], _ fn: @escaping @Sendable (A) -> [Result<B, E>]) -> [Result<B, E>] {
    arr.flatMapT(fn)
}

/// (-<<) :: (a -> [Result<b,e>]) -> [Result<a,e>] -> [Result<b,e>]
public func -<< <A, B, E: Error>(_ fn: @escaping @Sendable (A) -> [Result<B, E>], _ arr: [Result<A, E>]) -> [Result<B, E>] {
    arr.flatMapT(fn)
}

/// (>=>) :: (a -> [Result<b,e>]) -> (b -> [Result<c,e>]) -> a -> [Result<c,e>]
public func >=> <A, B, C, E: Error>(
    _ fn1: @escaping @Sendable (A) -> [Result<B, E>],
    _ fn2: @escaping @Sendable (B) -> [Result<C, E>]
) -> (A) -> [Result<C, E>] {
    kleisliT(fn1, fn2)
}
