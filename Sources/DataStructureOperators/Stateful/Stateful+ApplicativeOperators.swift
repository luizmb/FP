// SPDX-License-Identifier: Apache-2.0
import CoreFPOperators
import DataStructure
import Foundation

/// (<*>) :: Stateful<s, (a -> b)> -> Stateful<s, a> -> Stateful<s, b>
public func <*> <S, A, B>(
    _ sf: Stateful<S, @Sendable (A) -> B>,
    _ sa: Stateful<S, A>
) -> Stateful<S, B> {
    Stateful<S, B>.apply(sf, sa)
}

/// (*>) :: Stateful<s, a> -> Stateful<s, b> -> Stateful<s, b>
public func *> <S, A, B>(
    _ lhs: Stateful<S, A>,
    _ rhs: Stateful<S, B>
) -> Stateful<S, B> {
    lhs.seqRight(rhs)
}

/// (<*) :: Stateful<s, a> -> Stateful<s, b> -> Stateful<s, a>
public func <* <S, A, B>(
    _ lhs: Stateful<S, A>,
    _ rhs: Stateful<S, B>
) -> Stateful<S, A> {
    lhs.seqLeft(rhs)
}
