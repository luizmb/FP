// SPDX-License-Identifier: Apache-2.0
import CoreFPOperators
import DataStructure

/// (<£^>) :: (a -> b) -> Stateful<s, Reader<env, a>> -> Stateful<s, Reader<env, b>>
public func <£^> <S, Env, A, B>(
    _ fn: @escaping @Sendable (A) -> B,
    _ stateful: Stateful<S, Reader<Env, A>>
) -> Stateful<S, Reader<Env, B>> {
    stateful.mapT(fn)
}

/// (<&^>) :: Stateful<s, Reader<env, a>> -> (a -> b) -> Stateful<s, Reader<env, b>>
public func <&^> <S, Env, A, B>(
    _ stateful: Stateful<S, Reader<Env, A>>,
    _ fn: @escaping @Sendable (A) -> B
) -> Stateful<S, Reader<Env, B>> {
    stateful.mapT(fn)
}
