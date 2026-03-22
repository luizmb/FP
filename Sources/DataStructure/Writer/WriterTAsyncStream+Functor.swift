import Foundation
import CoreFP

public extension Writer {
    // WriterT + AsyncStream — Writer<W, AsyncStream<A>>

    @available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
    func mapT<Inner, B>(
        _ fn: @escaping @Sendable (Inner) -> B
    ) -> Writer<W, AsyncMapSequence<AsyncStream<Inner>, B>>
    where A == AsyncStream<Inner> {
        mapWriter { stream in stream.fmap(fn) }
    }

    @available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
    static func fmapT<Inner, B>(
        _ fn: @escaping @Sendable (Inner) -> B
    ) -> (Writer<W, AsyncStream<Inner>>) -> Writer<W, AsyncMapSequence<AsyncStream<Inner>, B>>
    where A == AsyncStream<Inner> {
        { $0.mapT(fn) }
    }
}
