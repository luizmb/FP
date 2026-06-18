// SPDX-License-Identifier: Apache-2.0
import CoreFPOperators
import DataStructure

/// (<£^>) :: (a -> b) -> Stateful<s, Either<l, a>> -> Stateful<s, Either<l, b>>
public func <£^> <S, L, A, B>(_ fn: @escaping @Sendable (A) -> B, _ stateful: Stateful<S, Either<L, A>>) -> Stateful<S, Either<L, B>>
where L: Sendable, A: Sendable {
    stateful.mapT(fn)
}

/// (<&^>) :: Stateful<s, Either<l, a>> -> (a -> b) -> Stateful<s, Either<l, b>>
public func <&^> <S, L, A, B>(_ stateful: Stateful<S, Either<L, A>>, _ fn: @escaping @Sendable (A) -> B) -> Stateful<S, Either<L, B>>
where L: Sendable, A: Sendable {
    stateful.mapT(fn)
}
