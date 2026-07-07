// SPDX-License-Identifier: Apache-2.0
import CoreFP
import CoreFPOperators
import DataStructure

// WriterTNonEmpty: outer = Writer, inner = NonEmpty
// Type: Writer<W, NonEmpty<A>>

/// (>>-) :: Writer<W, NonEmpty<A>> -> (A -> Writer<W, NonEmpty<B>?>) -> Writer<W, NonEmpty<B>?>
public func >>- <W: Monoid, A, B>(
    _ writer: Writer<W, NonEmpty<A>>,
    _ fn: @escaping @Sendable (A) -> Writer<W, NonEmpty<B>?>
) -> Writer<W, NonEmpty<B>?> {
    writer.flatMapT(fn)
}

/// (-<<) :: (A -> Writer<W, NonEmpty<B>?>) -> Writer<W, NonEmpty<A>> -> Writer<W, NonEmpty<B>?>
public func -<< <W: Monoid, A, B>(
    _ fn: @escaping @Sendable (A) -> Writer<W, NonEmpty<B>?>,
    _ writer: Writer<W, NonEmpty<A>>
) -> Writer<W, NonEmpty<B>?> {
    writer.flatMapT(fn)
}

/// (>=>) :: (A -> Writer<W, NonEmpty<B>?>) -> (B -> Writer<W, NonEmpty<C>?>) -> A -> Writer<W, NonEmpty<C>?>
public func >=> <W: Monoid, A, B, C>(
    _ fn1: @escaping @Sendable (A) -> Writer<W, NonEmpty<B>?>,
    _ fn2: @escaping @Sendable (B) -> Writer<W, NonEmpty<C>?>
) -> (A) -> Writer<W, NonEmpty<C>?> {
    kleisliT(fn1, fn2)
}
