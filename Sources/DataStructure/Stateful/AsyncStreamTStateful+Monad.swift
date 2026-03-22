import Foundation
import CoreFP

// AsyncStreamTStateful: outer = AsyncStream, inner = Stateful
// Type: AsyncStream<Stateful<S, A>>

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public extension AsyncStream {
    /// flatMapT :: AsyncStream<Stateful<s, a>> -> (a -> Stateful<s, b>) -> AsyncStream<Stateful<s, b>>
    func flatMapT<S, A, B>(_ fn: @escaping @Sendable (A) -> Stateful<S, B>) -> AsyncMapSequence<AsyncStream<Stateful<S, A>>, Stateful<S, B>>
    where Element == Stateful<S, A> {
        map { stateful in stateful.flatMap(fn) }
    }

    static func bindT<S, A, B>(
        _ fn: @escaping @Sendable (A) -> Stateful<S, B>
    ) -> (AsyncStream<Stateful<S, A>>) -> AsyncMapSequence<AsyncStream<Stateful<S, A>>, Stateful<S, B>> {
        { stream in stream.flatMapT(fn) }
    }
}
