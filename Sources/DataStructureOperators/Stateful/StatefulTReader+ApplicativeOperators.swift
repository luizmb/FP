// SPDX-License-Identifier: Apache-2.0
import CoreFPOperators
import DataStructure

/// (<*>) :: Stateful<s, Reader<env, (a -> b)>> -> Stateful<s, Reader<env, a>> -> Stateful<s, Reader<env, b>>
public func <*> <S, Env, A, B>(
    _ sf: Stateful<S, Reader<Env, @Sendable (A) -> B>>,
    _ sa: Stateful<S, Reader<Env, A>>
) -> Stateful<S, Reader<Env, B>> {
    applyStatefulReader(sf, sa)
}

/// (*>) :: Stateful<s, Reader<env, a>> -> Stateful<s, Reader<env, b>> -> Stateful<s, Reader<env, b>>
public func *> <S, Env, A, B>(_ lhs: Stateful<S, Reader<Env, A>>, _ rhs: Stateful<S, Reader<Env, B>>) -> Stateful<S, Reader<Env, B>> {
    seqRightStatefulReader(lhs, rhs)
}

/// (<*) :: Stateful<s, Reader<env, a>> -> Stateful<s, Reader<env, b>> -> Stateful<s, Reader<env, a>>
public func <* <S, Env, A, B>(_ lhs: Stateful<S, Reader<Env, A>>, _ rhs: Stateful<S, Reader<Env, B>>) -> Stateful<S, Reader<Env, A>> {
    seqLeftStatefulReader(lhs, rhs)
}
