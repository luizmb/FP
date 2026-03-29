#if canImport(Combine)
import Combine
import CoreFP
import CoreFPOperators
import DataStructure

// (>>-) :: AnyPublisher<Stateful<s, a>, e> -> (a -> Stateful<s, b>) -> AnyPublisher<Stateful<s, b>, e>
@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public func >>- <S, A, B, E: Error>(
    _ publisher: AnyPublisher<Stateful<S, A>, E>,
    _ fn: @escaping (A) -> Stateful<S, B>
) -> AnyPublisher<Stateful<S, B>, E> {
    publisher.flatMapT(fn)
}

// (-<<) :: (a -> Stateful<s, b>) -> AnyPublisher<Stateful<s, a>, e> -> AnyPublisher<Stateful<s, b>, e>
@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public func -<< <S, A, B, E: Error>(
    _ fn: @escaping (A) -> Stateful<S, B>,
    _ publisher: AnyPublisher<Stateful<S, A>, E>
) -> AnyPublisher<Stateful<S, B>, E> {
    publisher.flatMapT(fn)
}

#endif
