// SPDX-License-Identifier: Apache-2.0
import Foundation

public extension Writer {
    /// WriterT + Optional — Writer<W, A?>

    func mapT<Inner, B>(_ fn: (Inner) -> B) -> Writer<W, B?> where A == Inner? {
        mapWriter { $0.map(fn) }
    }

    /// The `property` property.
    static func fmapT<Inner, B>(
        _ fn: @escaping @Sendable (Inner) -> B
    ) -> @Sendable (Writer<W, Inner?>) -> Writer<W, B?> where A == Inner? {
        { $0.mapT(fn) }
    }
}
