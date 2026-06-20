// SPDX-License-Identifier: Apache-2.0
import CoreFP
import CoreFPOperators
import DataStructure

/// (<£^>) :: (a -> b) -> Writer<w, Result<a, e>> -> Writer<w, Result<b, e>>
public func <£^> <W: Monoid, A, B, E: Error>(
    _ fn: @escaping @Sendable (A) -> B,
    _ writer: Writer<W, Result<A, E>>
) -> Writer<W, Result<B, E>> {
    writer.mapT(fn)
}

/// (<&^>) :: Writer<w, Result<a, e>> -> (a -> b) -> Writer<w, Result<b, e>>
public func <&^> <W: Monoid, A, B, E: Error>(
    _ writer: Writer<W, Result<A, E>>,
    _ fn: @escaping @Sendable (A) -> B
) -> Writer<W, Result<B, E>> {
    writer.mapT(fn)
}
