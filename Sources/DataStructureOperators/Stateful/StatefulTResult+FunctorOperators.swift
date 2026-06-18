// SPDX-License-Identifier: Apache-2.0
import CoreFPOperators
import DataStructure

/// (<£^>) :: (a -> b) -> Stateful<s, Result<a, e>> -> Stateful<s, Result<b, e>>
public func <£^> <S, A, B, E: Error>(
    _ fn: @escaping @Sendable (A) -> B,
    _ stateful: Stateful<S, Result<A, E>>
) -> Stateful<S, Result<B, E>> {
    stateful.mapT(fn)
}

/// (<&^>) :: Stateful<s, Result<a, e>> -> (a -> b) -> Stateful<s, Result<b, e>>
public func <&^> <S, A, B, E: Error>(
    _ stateful: Stateful<S, Result<A, E>>,
    _ fn: @escaping @Sendable (A) -> B) -> Stateful<S, Result<B, E>> {
    stateful.mapT(fn)
}
