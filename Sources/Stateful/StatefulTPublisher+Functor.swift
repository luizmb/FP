#if canImport(Combine)
import Foundation
import FP
import Combine

public extension Stateful {
    // StatefulT + Publisher — Stateful<S, any Publisher<A, E>>

    @available(macOS 13.0, iOS 16.0, tvOS 16.0, watchOS 9.0, *)
    func mapT<Inner, B, E: Error>(
        _ fn: @escaping (Inner) -> B
    ) -> Stateful<S, any Publisher<B, E>>
    where A == any Publisher<Inner, E>, Inner: Sendable {
        mapStateful(AnyPublisher<Inner, E>.fmap(fn))
    }

    @available(macOS 13.0, iOS 16.0, tvOS 16.0, watchOS 9.0, *)
    static func fmapT<Inner, B, E: Error>(
        _ fn: @escaping (Inner) -> B
    ) -> (Stateful<S, any Publisher<Inner, E>>) -> Stateful<S, any Publisher<B, E>>
    where Inner: Sendable, A == any Publisher<Inner, E> {
        { $0.mapT(fn) }
    }
}

#endif
