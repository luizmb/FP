// SPDX-License-Identifier: Apache-2.0
import CoreFP
import CoreFPOperators
import DataStructure

/// (<£^>) :: (a -> b) -> Stateful<s, Writer<w, a>> -> Stateful<s, Writer<w, b>>
public func <£^> <S, W: Monoid, A, B>(
    _ fn: @escaping @Sendable (A) -> B,
    _ stateful: Stateful<S, Writer<W, A>>
) -> Stateful<S, Writer<W, B>> {
    stateful.mapT(fn)
}

/// (<&^>) :: Stateful<s, Writer<w, a>> -> (a -> b) -> Stateful<s, Writer<w, b>>
public func <&^> <S, W: Monoid, A, B>(
    _ stateful: Stateful<S, Writer<W, A>>,
    _ fn: @escaping @Sendable (A) -> B
) -> Stateful<S, Writer<W, B>> {
    stateful.mapT(fn)
}
