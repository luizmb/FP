#if canImport(Combine)
import Combine
import CoreFPOperators
import DataStructure

// (<£^>) :: (a -> b) -> AnyPublisher<Stateful<s, a>, e> -> AnyPublisher<Stateful<s, b>, e>
@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public func <£^> <S, A, B, E: Error>(
    _ fn: @escaping (A) -> B,
    _ publisher: AnyPublisher<Stateful<S, A>, E>
) -> AnyPublisher<Stateful<S, B>, E> {
    publisher.mapT(fn)
}

// (<&^>) :: AnyPublisher<Stateful<s, a>, e> -> (a -> b) -> AnyPublisher<Stateful<s, b>, e>
@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public func <&^> <S, A, B, E: Error>(
    _ publisher: AnyPublisher<Stateful<S, A>, E>,
    _ fn: @escaping (A) -> B
) -> AnyPublisher<Stateful<S, B>, E> {
    publisher.mapT(fn)
}

#endif
