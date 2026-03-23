import DataStructure
import CoreFPOperators
import CoreFP

// (<£^>) :: (a -> b) -> AsyncStream<Stateful<s, a>> -> AsyncMapSequence<AsyncStream<Stateful<s, a>>, Stateful<s, b>>
@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public func <£^> <S, A, B>(_ fn: @escaping @Sendable (A) -> B, _ stream: AsyncStream<Stateful<S, A>>) -> AsyncMapSequence<AsyncStream<Stateful<S, A>>, Stateful<S, B>> {
    stream.mapT(fn)
}

// (<&^>) :: AsyncStream<Stateful<s, a>> -> (a -> b) -> AsyncMapSequence<AsyncStream<Stateful<s, a>>, Stateful<s, b>>
@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public func <&^> <S, A, B>(_ stream: AsyncStream<Stateful<S, A>>, _ fn: @escaping @Sendable (A) -> B) -> AsyncMapSequence<AsyncStream<Stateful<S, A>>, Stateful<S, B>> {
    stream.mapT(fn)
}
