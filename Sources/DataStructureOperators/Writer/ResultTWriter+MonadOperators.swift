// SPDX-License-Identifier: Apache-2.0
import CoreFP
import CoreFPOperators
import DataStructure

/// (>>-) :: Result<Writer<w, a>, e> -> (a -> Writer<w, b>) -> Result<Writer<w, b>, e>
public func >>- <W: Monoid, A, B, E: Error>(
    _ result: Result<Writer<W, A>, E>,
    _ fn: @escaping @Sendable (A) -> Writer<W, B>
) -> Result<Writer<W, B>, E> {
    result.flatMapT(fn)
}

/// (-<<) :: (a -> Writer<w, b>) -> Result<Writer<w, a>, e> -> Result<Writer<w, b>, e>
public func -<< <W: Monoid, A, B, E: Error>(
    _ fn: @escaping @Sendable (A) -> Writer<W, B>,
    _ result: Result<Writer<W, A>, E>
) -> Result<Writer<W, B>, E> {
    result.flatMapT(fn)
}

/// (>=>) :: (a -> Result<Writer<w, b>, e>) -> (b -> Writer<w, c>) -> a -> Result<Writer<w, c>, e>
public func >=> <W: Monoid, A, B, C, E: Error>(
    _ fn1: @escaping @Sendable (A) -> Result<Writer<W, B>, E>,
    _ fn2: @escaping @Sendable (B) -> Writer<W, C>
) -> (A) -> Result<Writer<W, C>, E> {
    kleisliT(fn1, fn2)
}
