import DataStructure
import CoreFPOperators

// (<£^>) :: (a -> b) -> Stateful<s, AsyncStream<a>> -> Stateful<s, AsyncMapSequence<AsyncStream<a>, b>>
@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public func <£^> <S, A, B>(
    _ fn: @escaping @Sendable (A) -> B,
    _ stateful: Stateful<S, AsyncStream<A>>
) -> Stateful<S, AsyncMapSequence<AsyncStream<A>, B>> {
    stateful.mapT(fn)
}

// (<&^>) :: Stateful<s, AsyncStream<a>> -> (a -> b) -> Stateful<s, AsyncMapSequence<AsyncStream<a>, b>>
@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public func <&^> <S, A, B>(
    _ stateful: Stateful<S, AsyncStream<A>>,
    _ fn: @escaping @Sendable (A) -> B
) -> Stateful<S, AsyncMapSequence<AsyncStream<A>, B>> {
    stateful.mapT(fn)
}
