// SPDX-License-Identifier: Apache-2.0
import CoreFP
import Foundation

// EitherTWriter: outer = Either, inner = Writer
// Type: Either<L, Writer<W, A>>

public extension Either {
    /// Declaration.
    func mapT<W: Monoid, Inner, C>(_ fn: @escaping @Sendable (Inner) -> C) -> Either<A, Writer<W, C>>
    where B == Writer<W, Inner> {
        mapRight { writer in writer.map(fn) }
    }

    /// The `property` property.
    static func fmapT<W: Monoid, Inner, C>(
        _ fn: @escaping @Sendable (Inner) -> C
    ) -> @Sendable (Either<A, Writer<W, Inner>>) -> Either<A, Writer<W, C>> {
        { either in either.mapT(fn) }
    }
}
