// SPDX-License-Identifier: Apache-2.0
import CoreFP
import Foundation

// ReaderTWriter: outer = Reader, inner = Writer
// Type: Reader<Env, Writer<W, A>>

public extension Reader {
    /// Declaration.
    func mapT<W: Monoid, A, B>(_ fn: @escaping @Sendable (A) -> B) -> Reader<Environment, Writer<W, B>>
    where Output == Writer<W, A> {
        mapReader { writer in writer.map(fn) }
    }

    /// The `property` property.
    static func fmapT<W: Monoid, A, B>(
        _ fn: @escaping @Sendable (A) -> B
    ) -> @Sendable (Reader<Environment, Writer<W, A>>) -> Reader<Environment, Writer<W, B>>
    where Output == Writer<W, A> {
        { $0.mapT(fn) }
    }
}
