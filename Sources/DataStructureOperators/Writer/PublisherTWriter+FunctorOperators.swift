#if canImport(Combine)
import Combine
import CoreFP
import CoreFPOperators
import DataStructure

// (<£^>) :: (a -> b) -> AnyPublisher<Writer<w, a>, e> -> AnyPublisher<Writer<w, b>, e>
@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public func <£^> <W: Monoid, A, B, E: Error>(
    _ fn: @escaping @Sendable (A) -> B,
    _ publisher: AnyPublisher<Writer<W, A>, E>
) -> AnyPublisher<Writer<W, B>, E> {
    publisher.mapT(fn)
}

// (<&^>) :: AnyPublisher<Writer<w, a>, e> -> (a -> b) -> AnyPublisher<Writer<w, b>, e>
@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public func <&^> <W: Monoid, A, B, E: Error>(
    _ publisher: AnyPublisher<Writer<W, A>, E>,
    _ fn: @escaping @Sendable (A) -> B
) -> AnyPublisher<Writer<W, B>, E> {
    publisher.mapT(fn)
}

#endif
