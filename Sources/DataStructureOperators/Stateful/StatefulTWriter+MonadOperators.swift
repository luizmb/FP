// SPDX-License-Identifier: Apache-2.0
import CoreFP
import CoreFPOperators
import DataStructure

// StatefulTWriter: outer = Stateful, inner = Writer
// Type: Stateful<S, Writer<W, A>>

/// (>>-) :: Stateful<s, Writer<w, a>> -> (a -> Stateful<s, Writer<w, b>>) -> Stateful<s, Writer<w, b>>
public func >>- <S, W: Monoid, A, B>(
    _ stateful: Stateful<S, Writer<W, A>>,
    _ fn: @escaping @Sendable (A) -> Stateful<S, Writer<W, B>>
) -> Stateful<S, Writer<W, B>> {
    stateful.flatMapT(fn)
}

/// (-<<) :: (a -> Stateful<s, Writer<w, b>>) -> Stateful<s, Writer<w, a>> -> Stateful<s, Writer<w, b>>
public func -<< <S, W: Monoid, A, B>(
    _ fn: @escaping @Sendable (A) -> Stateful<S, Writer<W, B>>,
    _ stateful: Stateful<S, Writer<W, A>>
) -> Stateful<S, Writer<W, B>> {
    stateful.flatMapT(fn)
}

/// (>=>) :: (a -> Stateful<s, Writer<w, b>>) -> (b -> Stateful<s, Writer<w, c>>) -> a -> Stateful<s, Writer<w, c>>
public func >=> <S, W: Monoid, A, B, C>(
    _ fn1: @escaping @Sendable (A) -> Stateful<S, Writer<W, B>>,
    _ fn2: @escaping @Sendable (B) -> Stateful<S, Writer<W, C>>
) -> @Sendable (A) -> Stateful<S, Writer<W, C>> {
    kleisliT(fn1, fn2)
}
