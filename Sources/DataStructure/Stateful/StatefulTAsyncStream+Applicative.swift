import Foundation
import Core

// StatefulT + AsyncStream — free functions for Stateful<S, AsyncStream<A>>

/// liftA2 for Stateful<S, AsyncStream>
@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public func liftA2StatefulAsyncStream<S, A, B, C>(
    _ fn: @escaping @Sendable (A, B) -> C
) -> (Stateful<S, AsyncStream<A>>, Stateful<S, AsyncStream<B>>) -> Stateful<S, AsyncMapSequence<AsyncStream<(A, B)>, C>>
where A: Sendable, B: Sendable, C: Sendable {
    { sa, sb in
        Stateful<S, AsyncMapSequence<AsyncStream<(A, B)>, C>> { s in
            let streamA = sa.run(&s)
            let streamB = sb.run(&s)
            return AsyncStream<(A, B)>.zip(streamA, streamB).map { fn($0.0, $0.1) }
        }
    }
}

/// seqRight for Stateful<S, AsyncStream>
@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public func seqRightStatefulAsyncStream<S, A, B>(
    _ lhs: Stateful<S, AsyncStream<A>>,
    _ rhs: Stateful<S, AsyncStream<B>>
) -> Stateful<S, AsyncMapSequence<AsyncStream<(A, B)>, B>>
where A: Sendable, B: Sendable {
    liftA2StatefulAsyncStream { @Sendable (_: A, b: B) in b }(lhs, rhs)
}

/// seqLeft for Stateful<S, AsyncStream>
@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public func seqLeftStatefulAsyncStream<S, A, B>(
    _ lhs: Stateful<S, AsyncStream<A>>,
    _ rhs: Stateful<S, AsyncStream<B>>
) -> Stateful<S, AsyncMapSequence<AsyncStream<(A, B)>, A>>
where A: Sendable, B: Sendable {
    liftA2StatefulAsyncStream { @Sendable (a: A, _: B) in a }(lhs, rhs)
}
