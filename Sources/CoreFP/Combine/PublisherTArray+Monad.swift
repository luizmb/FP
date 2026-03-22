#if canImport(Combine)
import Combine
import Foundation

// PublisherTArray: outer = AnyPublisher, inner = Array
// Type: AnyPublisher<[A], E>

/// flatMapT for AnyPublisher<[A], E>
/// For each emitted [A], apply fn to each element producing AnyPublisher<[B], E>,
/// then zip all results and concatenate.
/// For simplicity: flatMap the outer publisher, map inner array with fn, zip results.
@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public func flatMapTPublisherArray<A, B, E: Error>(
    _ publisher: AnyPublisher<[A], E>,
    _ fn: @escaping (A) -> AnyPublisher<[B], E>
) -> AnyPublisher<[B], E> {
    publisher.flatMap { arr -> AnyPublisher<[B], E> in
        let publishers = arr.map(fn)
        guard !publishers.isEmpty else {
            return Just([]).setFailureType(to: E.self).eraseToAnyPublisher()
        }
        return publishers.dropFirst().reduce(publishers[0]) { acc, next in
            acc.zip(next).map { $0 + $1 }.eraseToAnyPublisher()
        }
    }.eraseToAnyPublisher()
}

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public func bindTPublisherArray<A, B, E: Error>(
    _ fn: @escaping (A) -> AnyPublisher<[B], E>
) -> (AnyPublisher<[A], E>) -> AnyPublisher<[B], E> {
    { publisher in flatMapTPublisherArray(publisher, fn) }
}

#endif
