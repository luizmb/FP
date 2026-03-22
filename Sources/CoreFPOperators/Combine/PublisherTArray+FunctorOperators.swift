#if canImport(Combine)
import Combine
import CoreFP

// PublisherTArray: AnyPublisher<[A], E>

// (<£>) :: (a -> b) -> AnyPublisher<[a],e> -> AnyPublisher<[b],e>
@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public func <£> <A, B, E: Error>(_ fn: @escaping (A) -> B, _ pub: AnyPublisher<[A], E>) -> AnyPublisher<[B], E> {
    mapTPublisherArray(fn, pub)
}

// (<&>) :: AnyPublisher<[a],e> -> (a -> b) -> AnyPublisher<[b],e>
@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public func <&> <A, B, E: Error>(_ pub: AnyPublisher<[A], E>, _ fn: @escaping (A) -> B) -> AnyPublisher<[B], E> {
    mapTPublisherArray(fn, pub)
}
#endif
