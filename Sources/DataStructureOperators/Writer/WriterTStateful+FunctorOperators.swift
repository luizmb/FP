// SPDX-License-Identifier: Apache-2.0
import CoreFP
import CoreFPOperators
import DataStructure

/// (<£^>) :: (a -> b) -> Writer<w, Stateful<s, a>> -> Writer<w, Stateful<s, b>>
public func <£^> <W: Monoid, S, A, B>(
    _ fn: @escaping @Sendable (A) -> B,
    _ writer: Writer<W, Stateful<S, A>>
) -> Writer<W, Stateful<S, B>> {
    writer.mapT(fn)
}

/// (<&^>) :: Writer<w, Stateful<s, a>> -> (a -> b) -> Writer<w, Stateful<s, b>>
public func <&^> <W: Monoid, S, A, B>(
    _ writer: Writer<W, Stateful<S, A>>,
    _ fn: @escaping @Sendable (A) -> B) -> Writer<W, Stateful<S, B>> {
    writer.mapT(fn)
}
