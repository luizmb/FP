// SPDX-License-Identifier: Apache-2.0
import CoreFPOperators
import DataStructure

/// (>>-) :: [Stateful<s, a>] -> (a -> Stateful<s, b>) -> [Stateful<s, b>]
public func >>- <S, A, B>(_ arr: [Stateful<S, A>], _ fn: @escaping @Sendable (A) -> Stateful<S, B>) -> [Stateful<S, B>] {
    arr.flatMapT(fn)
}

/// (-<<) :: (a -> Stateful<s, b>) -> [Stateful<s, a>] -> [Stateful<s, b>]
public func -<< <S, A, B>(_ fn: @escaping @Sendable (A) -> Stateful<S, B>, _ arr: [Stateful<S, A>]) -> [Stateful<S, B>] {
    arr.flatMapT(fn)
}

/// (>=>) :: (a -> [Stateful<s, b>]) -> (b -> Stateful<s, c>) -> a -> [Stateful<s, c>]
public func >=> <S, A, B, C>(
    _ fn1: @escaping @Sendable (A) -> [Stateful<S, B>],
    _ fn2: @escaping @Sendable (B) -> Stateful<S, C>
) -> (A) -> [Stateful<S, C>] {
    { a in fn1(a).flatMapT(fn2) }
}
