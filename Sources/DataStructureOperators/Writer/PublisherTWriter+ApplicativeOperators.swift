#if canImport(Combine)
import Combine
import CoreFP
import DataStructure
import CoreFPOperators

// (*>) :: AnyPublisher<Writer<w, a>, e> -> AnyPublisher<Writer<w, b>, e> -> AnyPublisher<Writer<w, b>, e>
@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public func *> <W: Monoid, A, B, E: Error>(
    _ lhs: AnyPublisher<Writer<W, A>, E>,
    _ rhs: AnyPublisher<Writer<W, B>, E>
) -> AnyPublisher<Writer<W, B>, E> {
    seqRightPublisherWriter(lhs, rhs)
}

// (<*) :: AnyPublisher<Writer<w, a>, e> -> AnyPublisher<Writer<w, b>, e> -> AnyPublisher<Writer<w, a>, e>
@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public func <* <W: Monoid, A, B, E: Error>(
    _ lhs: AnyPublisher<Writer<W, A>, E>,
    _ rhs: AnyPublisher<Writer<W, B>, E>
) -> AnyPublisher<Writer<W, A>, E> {
    seqLeftPublisherWriter(lhs, rhs)
}

#endif
