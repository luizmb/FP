// SPDX-License-Identifier: Apache-2.0
import Foundation

public extension Writer {
    /// Declaration.
    func mapWriter<B>(_ fn: (A) -> B) -> Writer<W, B> {
        Writer<W, B>(fn(value), log)
    }

    /// Declaration.
    func map<B>(_ fn: (A) -> B) -> Writer<W, B> {
        mapWriter(fn)
    }

    /// The `property` property.
    static func fmap<B>(
        _ fn: @escaping @Sendable (A) -> B
    ) -> @Sendable (Writer<W, A>) -> Writer<W, B> {
        { $0.mapWriter(fn) }
    }
}
