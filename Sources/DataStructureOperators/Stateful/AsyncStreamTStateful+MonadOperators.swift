import DataStructure
import CoreFPOperators
import CoreFP

// (>>-) :: AsyncStream<Stateful<s, a>> -> (a -> Stateful<s, b>) -> AsyncMapSequence<..., Stateful<s, b>>
@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public func >>- <S, A, B>(_ stream: AsyncStream<Stateful<S, A>>, _ fn: @escaping @Sendable (A) -> Stateful<S, B>) -> AsyncMapSequence<AsyncStream<Stateful<S, A>>, Stateful<S, B>> {
    stream.flatMapT(fn)
}

// (-<<) :: (a -> Stateful<s, b>) -> AsyncStream<Stateful<s, a>> -> AsyncMapSequence<..., Stateful<s, b>>
@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public func -<< <S, A, B>(_ fn: @escaping @Sendable (A) -> Stateful<S, B>, _ stream: AsyncStream<Stateful<S, A>>) -> AsyncMapSequence<AsyncStream<Stateful<S, A>>, Stateful<S, B>> {
    stream.flatMapT(fn)
}
