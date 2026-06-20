// SPDX-License-Identifier: Apache-2.0
import CoreFP
import Foundation

// AsyncStreamTWriter: outer = AsyncStream, inner = Writer
// Type: AsyncStream<Writer<W, A>>

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public extension AsyncStream {
    /// Declaration.
    func mapT<W: Monoid, A, B>(_ fn: @escaping @Sendable (A) -> B) -> AsyncMapSequence<AsyncStream<Writer<W, A>>, Writer<W, B>>
    where Element == Writer<W, A> {
        map { writer in writer.map(fn) }
    }

    /// The `property` property.
    static func fmapT<W: Monoid, A, B>(
        _ fn: @escaping @Sendable (A) -> B
    ) -> @Sendable (AsyncStream<Writer<W, A>>) -> AsyncMapSequence<AsyncStream<Writer<W, A>>, Writer<W, B>> {
        { stream in stream.mapT(fn) }
    }
}
