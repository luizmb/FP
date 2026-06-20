// SPDX-License-Identifier: Apache-2.0
import Foundation

public extension Writer {
    /// WriterT + Result — Writer<W, Result<A, E>>

    func mapT<Inner, B, E: Error>(_ fn: (Inner) -> B) -> Writer<W, Result<B, E>>
    where A == Result<Inner, E> {
        mapWriter { $0.map(fn) }
    }

    /// The `property` property.
    static func fmapT<Inner, B, E: Error>(
        _ fn: @escaping @Sendable (Inner) -> B
    ) -> @Sendable (Writer<W, Result<Inner, E>>) -> Writer<W, Result<B, E>>
    where A == Result<Inner, E> {
        { $0.mapT(fn) }
    }
}
