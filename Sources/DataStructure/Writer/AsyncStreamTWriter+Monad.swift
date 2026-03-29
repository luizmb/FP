import CoreFP
import Foundation

// AsyncStreamTWriter: outer = AsyncStream, inner = Writer
// Type: AsyncStream<Writer<W, A>>

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public extension AsyncStream {
    /// flatMapT :: AsyncStream<Writer<w, a>> -> (a -> Writer<w, b>) -> AsyncStream<Writer<w, b>>
    func flatMapT<W: Monoid, A, B>(_ fn: @escaping @Sendable (A) -> Writer<W, B>)
    -> AsyncMapSequence<AsyncStream<Writer<W, A>>, Writer<W, B>>
    where Element == Writer<W, A> {
        map { writer in writer.flatMap(fn) }
    }

    static func bindT<W: Monoid, A, B>(
        _ fn: @escaping @Sendable (A) -> Writer<W, B>
    ) -> (AsyncStream<Writer<W, A>>) -> AsyncMapSequence<AsyncStream<Writer<W, A>>, Writer<W, B>> {
        { stream in stream.flatMapT(fn) }
    }
}
