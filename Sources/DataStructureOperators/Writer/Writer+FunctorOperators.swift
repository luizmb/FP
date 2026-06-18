// SPDX-License-Identifier: Apache-2.0
import CoreFP
import CoreFPOperators
import DataStructure
import Foundation

/// (<$>) :: (a -> b) -> Writer<w, a> -> Writer<w, b>
public func <£> <W: Monoid, A, B>(
    _ transform: @escaping @Sendable (A) -> B,
    _ writer: Writer<W, A>
) -> Writer<W, B> {
    writer.map(transform)
}

/// ($>) :: Writer<w, a> -> b -> Writer<w, b>
public func £> <W: Monoid, A, B>(
    _ writer: Writer<W, A>,
    _ value: B
) -> Writer<W, B> {
    writer.map(const(value))
}

/// (<$) :: b -> Writer<w, a> -> Writer<w, b>
public func <£ <W: Monoid, A, B>(
    _ value: B,
    _ writer: Writer<W, A>
) -> Writer<W, B> {
    writer £> value
}

/// (<&>) :: Writer<w, a> -> (a -> b) -> Writer<w, b>
public func <&> <W: Monoid, A, B>(
    _ writer: Writer<W, A>,
    _ transform: @escaping @Sendable (A) -> B
) -> Writer<W, B> {
    writer.mapWriter(transform)
}
