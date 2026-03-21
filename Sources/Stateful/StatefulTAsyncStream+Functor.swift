import Foundation
import FP

public extension Stateful {
    // StatefulT + AsyncStream — Stateful<S, AsyncStream<A>>

    @available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
    func mapT<Inner, B>(
        _ fn: @escaping @Sendable (Inner) -> B
    ) -> Stateful<S, AsyncMapSequence<AsyncStream<Inner>, B>>
    where A == AsyncStream<Inner> {
        mapStateful { stream in stream.fmap(fn) }
    }

    @available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
    static func fmapT<Inner, B>(
        _ fn: @escaping @Sendable (Inner) -> B
    ) -> (Stateful<S, AsyncStream<Inner>>) -> Stateful<S, AsyncMapSequence<AsyncStream<Inner>, B>>
    where A == AsyncStream<Inner> {
        { $0.mapT(fn) }
    }
}
