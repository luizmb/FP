// SPDX-License-Identifier: Apache-2.0
import CoreFPOperators
import DataStructure

/// (<*>) :: Result<Stateful<s, (a -> b)>, e> -> Result<Stateful<s, a>, e> -> Result<Stateful<s, b>, e>
public func <*> <S, A, B, E: Error>(
    _ rf: Result<Stateful<S, @Sendable (A) -> B>, E>,
    _ ra: Result<Stateful<S, A>, E>
) -> Result<Stateful<S, B>, E> {
    applyResultStateful(rf, ra)
}

/// (*>) :: Result<Stateful<s, a>, e> -> Result<Stateful<s, b>, e> -> Result<Stateful<s, b>, e>
public func *> <S, A, B, E: Error>(_ lhs: Result<Stateful<S, A>, E>, _ rhs: Result<Stateful<S, B>, E>) -> Result<Stateful<S, B>, E> {
    seqRightResultStateful(lhs, rhs)
}

/// (<*) :: Result<Stateful<s, a>, e> -> Result<Stateful<s, b>, e> -> Result<Stateful<s, a>, e>
public func <* <S, A, B, E: Error>(_ lhs: Result<Stateful<S, A>, E>, _ rhs: Result<Stateful<S, B>, E>) -> Result<Stateful<S, A>, E> {
    seqLeftResultStateful(lhs, rhs)
}
