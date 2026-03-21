import Foundation
import FP

// AsyncStreamTStateful: outer = AsyncStream, inner = Stateful
// Type: AsyncStream<Stateful<S, A>>

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public extension AsyncStream {
    func mapT<S, A, B>(_ fn: @escaping @Sendable (A) -> B) -> AsyncMapSequence<AsyncStream<Stateful<S, A>>, Stateful<S, B>>
    where Element == Stateful<S, A> {
        map { stateful in stateful.fmap(fn) }
    }

    static func fmapT<S, A, B>(
        _ fn: @escaping @Sendable (A) -> B
    ) -> (AsyncStream<Stateful<S, A>>) -> AsyncMapSequence<AsyncStream<Stateful<S, A>>, Stateful<S, B>> {
        { stream in stream.mapT(fn) }
    }
}
