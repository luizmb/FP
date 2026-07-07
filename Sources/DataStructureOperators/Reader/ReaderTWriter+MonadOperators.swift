// SPDX-License-Identifier: Apache-2.0
import CoreFP
import CoreFPOperators
import DataStructure

// ReaderTWriter: outer = Reader, inner = Writer
// Type: Reader<Env, Writer<W, A>>

/// (>>-) :: Reader<env, Writer<w, a>> -> (a -> Writer<w, b>) -> Reader<env, Writer<w, b>>
public func >>- <Env, W: Monoid, A, B>(
    _ reader: Reader<Env, Writer<W, A>>,
    _ fn: @escaping @Sendable (A) -> Writer<W, B>
) -> Reader<Env, Writer<W, B>> {
    reader.flatMapT(fn)
}

/// (-<<) :: (a -> Writer<w, b>) -> Reader<env, Writer<w, a>> -> Reader<env, Writer<w, b>>
public func -<< <Env, W: Monoid, A, B>(
    _ fn: @escaping @Sendable (A) -> Writer<W, B>,
    _ reader: Reader<Env, Writer<W, A>>
) -> Reader<Env, Writer<W, B>> {
    reader.flatMapT(fn)
}

/// (>=>) :: (a -> Reader<env, Writer<w, b>>) -> (b -> Writer<w, c>) -> a -> Reader<env, Writer<w, c>>
public func >=> <Env, W: Monoid, A, B, C>(
    _ fn1: @escaping @Sendable (A) -> Reader<Env, Writer<W, B>>,
    _ fn2: @escaping @Sendable (B) -> Writer<W, C>
) -> (A) -> Reader<Env, Writer<W, C>> {
    kleisliT(fn1, fn2)
}
