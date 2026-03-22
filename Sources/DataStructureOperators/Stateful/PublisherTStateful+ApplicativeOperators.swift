#if canImport(Combine)
import DataStructure
import CoreFPOperators
import CoreFP
import Combine

// (*>) :: AnyPublisher<Stateful<s, a>, e> -> AnyPublisher<Stateful<s, b>, e> -> AnyPublisher<Stateful<s, b>, e>
@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public func *> <S, A, B, E: Error>(_ lhs: AnyPublisher<Stateful<S, A>, E>, _ rhs: AnyPublisher<Stateful<S, B>, E>) -> AnyPublisher<Stateful<S, B>, E> {
    seqRightPublisherStateful(lhs, rhs)
}

// (<*) :: AnyPublisher<Stateful<s, a>, e> -> AnyPublisher<Stateful<s, b>, e> -> AnyPublisher<Stateful<s, a>, e>
@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public func <* <S, A, B, E: Error>(_ lhs: AnyPublisher<Stateful<S, A>, E>, _ rhs: AnyPublisher<Stateful<S, B>, E>) -> AnyPublisher<Stateful<S, A>, E> {
    seqLeftPublisherStateful(lhs, rhs)
}

#endif
