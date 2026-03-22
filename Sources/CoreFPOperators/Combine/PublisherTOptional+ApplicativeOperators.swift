#if canImport(Combine)
import Combine
import CoreFP

// PublisherTOptional: AnyPublisher<A?, E>

// (*>) :: AnyPublisher<a?,e> -> AnyPublisher<b?,e> -> AnyPublisher<b?,e>
@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public func *> <A, B, E: Error>(_ lhs: AnyPublisher<A?, E>, _ rhs: AnyPublisher<B?, E>) -> AnyPublisher<B?, E> {
    seqRightPublisherOptional(lhs, rhs)
}

// (<*) :: AnyPublisher<a?,e> -> AnyPublisher<b?,e> -> AnyPublisher<a?,e>
@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public func <* <A, B, E: Error>(_ lhs: AnyPublisher<A?, E>, _ rhs: AnyPublisher<B?, E>) -> AnyPublisher<A?, E> {
    seqLeftPublisherOptional(lhs, rhs)
}
#endif
