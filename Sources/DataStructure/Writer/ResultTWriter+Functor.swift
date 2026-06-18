// SPDX-License-Identifier: Apache-2.0
import CoreFP
import Foundation

// ResultTWriter: outer = Result, inner = Writer
// Type: Result<Writer<W, A>, E>

public extension Result {
    /// Declaration.
    func mapT<W: Monoid, A, B>(_ fn: (A) -> B) -> Result<Writer<W, B>, Failure>
    where Success == Writer<W, A> {
        map { writer in writer.map(fn) }
    }

    /// The `property` property.
    static func fmapT<W: Monoid, A, B>(
        _ fn: @escaping @Sendable (A) -> B
    ) -> @Sendable (Result<Writer<W, A>, Failure>) -> Result<Writer<W, B>, Failure> {
        { result in result.mapT(fn) }
    }
}
