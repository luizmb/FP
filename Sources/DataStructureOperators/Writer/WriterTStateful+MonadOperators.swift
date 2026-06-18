// SPDX-License-Identifier: Apache-2.0
import CoreFP
import CoreFPOperators
import DataStructure

/// (>>-) :: Writer<w, Stateful<s, a>> -> (a -> Writer<w, Stateful<s, b>>) -> Writer<w, Stateful<s, b>>
public func >>- <W: Monoid, S, A, B>(
    _ writer: Writer<W, Stateful<S, A>>,
    _ fn: @escaping @Sendable (A) -> Writer<W, Stateful<S, B>>
) -> Writer<W, Stateful<S, B>> {
    writer.flatMapT(fn)
}

/// (-<<) :: (a -> Writer<w, Stateful<s, b>>) -> Writer<w, Stateful<s, a>> -> Writer<w, Stateful<s, b>>
public func -<< <W: Monoid, S, A, B>(
    _ fn: @escaping @Sendable (A) -> Writer<W, Stateful<S, B>>,
    _ writer: Writer<W, Stateful<S, A>>
) -> Writer<W, Stateful<S, B>> {
    writer.flatMapT(fn)
}

/// (>=>) :: (a -> Writer<w, Stateful<s, b>>) -> (b -> Writer<w, Stateful<s, c>>) -> a -> Writer<w, Stateful<s, c>>
public func >=> <W: Monoid, S, A, B, C>(
    _ fn1: @escaping @Sendable (A) -> Writer<W, Stateful<S, B>>,
    _ fn2: @escaping @Sendable (B) -> Writer<W, Stateful<S, C>>
) -> (A) -> Writer<W, Stateful<S, C>> {
    { a in fn1(a).flatMapT(fn2) }
}
