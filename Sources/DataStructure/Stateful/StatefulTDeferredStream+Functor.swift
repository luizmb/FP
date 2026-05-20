import CoreFP

// StatefulTDeferredStream: outer = Stateful, inner = DeferredStream
// Type: Stateful<S, DeferredStream<A>>

public extension Stateful {
    func mapT<Inner: Sendable, B: Sendable>(
        _ fn: @escaping @Sendable (Inner) -> B
    ) -> Stateful<S, DeferredStream<B>>
    where A == DeferredStream<Inner> {
        mapStateful { stream in stream.map(fn) }
    }

    static func fmapT<Inner: Sendable, B: Sendable>(
        _ fn: @escaping @Sendable (Inner) -> B
    ) -> @Sendable (Stateful<S, DeferredStream<Inner>>) -> Stateful<S, DeferredStream<B>>
    where A == DeferredStream<Inner> {
        { $0.mapT(fn) }
    }
}
