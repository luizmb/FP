// SPDX-License-Identifier: Apache-2.0
#if canImport(Combine)
import Combine
import CoreFP
import CoreFPOperators
import DataStructure

// (*>) :: AnyPublisher<Writer<w, a>, e> -> AnyPublisher<Writer<w, b>, e> -> AnyPublisher<Writer<w, b>, e>
/// `*>` overload.
@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public func *> <W: Monoid, A, B, E: Error>(
    _ lhs: AnyPublisher<Writer<W, A>, E>,
    _ rhs: AnyPublisher<Writer<W, B>, E>
) -> AnyPublisher<Writer<W, B>, E> {
    seqRightPublisherWriter(lhs, rhs)
}

// (<*) :: AnyPublisher<Writer<w, a>, e> -> AnyPublisher<Writer<w, b>, e> -> AnyPublisher<Writer<w, a>, e>
/// `func`.
@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public func <* <W: Monoid, A, B, E: Error>(
    _ lhs: AnyPublisher<Writer<W, A>, E>,
    _ rhs: AnyPublisher<Writer<W, B>, E>
) -> AnyPublisher<Writer<W, A>, E> {
    seqLeftPublisherWriter(lhs, rhs)
}

#endif
