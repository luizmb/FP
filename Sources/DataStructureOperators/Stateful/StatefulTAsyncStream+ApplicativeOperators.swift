import DataStructure
import CoreFPOperators

// (*>) :: Stateful<s, AsyncStream<a>> -> Stateful<s, AsyncStream<b>> -> Stateful<s, AsyncMapSequence<...>>
// Note: <*> is not available — AsyncStream has no apply free function due to its complex return type.
// Use liftA2StatefulAsyncStream for general applicative lifting.
@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public func *> <S, A: Sendable, B: Sendable>(
    _ lhs: Stateful<S, AsyncStream<A>>,
    _ rhs: Stateful<S, AsyncStream<B>>
) -> Stateful<S, AsyncMapSequence<AsyncStream<(A, B)>, B>> {
    seqRightStatefulAsyncStream(lhs, rhs)
}

// (<*) :: Stateful<s, AsyncStream<a>> -> Stateful<s, AsyncStream<b>> -> Stateful<s, AsyncMapSequence<...>>
@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public func <* <S, A: Sendable, B: Sendable>(
    _ lhs: Stateful<S, AsyncStream<A>>,
    _ rhs: Stateful<S, AsyncStream<B>>
) -> Stateful<S, AsyncMapSequence<AsyncStream<(A, B)>, A>> {
    seqLeftStatefulAsyncStream(lhs, rhs)
}
