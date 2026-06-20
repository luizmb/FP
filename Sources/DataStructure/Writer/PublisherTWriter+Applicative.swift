// SPDX-License-Identifier: Apache-2.0
#if canImport(Combine)
    import Combine
    import CoreFP
    import Foundation

    // PublisherTWriter: outer = AnyPublisher, inner = Writer
    // Type: AnyPublisher<Writer<W, A>, E>

    /// liftA2 for PublisherTWriter
    @available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
    public func liftA2PublisherWriter<W: Monoid, A, B, C, E: Error>(
        _ fn: @escaping @Sendable (A, B) -> C
    ) -> (AnyPublisher<Writer<W, A>, E>, AnyPublisher<Writer<W, B>, E>) -> AnyPublisher<Writer<W, C>, E> {
        { pubA, pubB in
            pubA.zip(pubB)
                .map { wa, wb in Writer<W, C>(fn(wa.value, wb.value), W.combine(wa.log, wb.log)) }
                .eraseToAnyPublisher()
        }
    }

    /// seqRight for PublisherTWriter
    @available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
    public func seqRightPublisherWriter<W: Monoid, A, B, E: Error>(
        _ lhs: AnyPublisher<Writer<W, A>, E>,
        _ rhs: AnyPublisher<Writer<W, B>, E>
    ) -> AnyPublisher<Writer<W, B>, E> {
        lhs.zip(rhs)
            .map { wa, wb in Writer<W, B>(wb.value, W.combine(wa.log, wb.log)) }
            .eraseToAnyPublisher()
    }

    /// seqLeft for PublisherTWriter
    @available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
    public func seqLeftPublisherWriter<W: Monoid, A, B, E: Error>(
        _ lhs: AnyPublisher<Writer<W, A>, E>,
        _ rhs: AnyPublisher<Writer<W, B>, E>
    ) -> AnyPublisher<Writer<W, A>, E> {
        lhs.zip(rhs)
            .map { wa, wb in Writer<W, A>(wa.value, W.combine(wa.log, wb.log)) }
            .eraseToAnyPublisher()
    }

#endif
