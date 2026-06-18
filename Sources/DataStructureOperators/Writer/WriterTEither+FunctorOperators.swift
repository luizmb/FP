// SPDX-License-Identifier: Apache-2.0
import CoreFP
import CoreFPOperators
import DataStructure

/// (<£^>) :: (a -> b) -> Writer<w, Either<l, a>> -> Writer<w, Either<l, b>>
public func <£^> <W: Monoid, L, A, B>(_ fn: @escaping @Sendable (A) -> B, _ writer: Writer<W, Either<L, A>>) -> Writer<W, Either<L, B>> {
    writer.mapT(fn)
}

/// (<&^>) :: Writer<w, Either<l, a>> -> (a -> b) -> Writer<w, Either<l, b>>
public func <&^> <W: Monoid, L, A, B>(_ writer: Writer<W, Either<L, A>>, _ fn: @escaping @Sendable (A) -> B) -> Writer<W, Either<L, B>> {
    writer.mapT(fn)
}
