// SPDX-License-Identifier: Apache-2.0
#if canImport(Combine)
    import Combine
    import CoreFP
    import Foundation

    // WriterT + Publisher — free functions for Writer<W, any Publisher<A, E>>
    // The inner applicative is Publisher's own (`ap`: cartesian, derived from the ordered-concat bind);
    // the logs are combined left to right.

    /// liftA2 for Writer<W, Publisher>
    @available(macOS 13.0, iOS 16.0, tvOS 16.0, watchOS 9.0, *)
    func liftA2WriterPublisher<W: Monoid, A, B, C, E: Error>(
        _ fn: @escaping @Sendable (A, B) -> C
    ) -> (Writer<W, any Publisher<A, E>>, Writer<W, any Publisher<B, E>>) -> Writer<W, any Publisher<C, E>> {
        { wa, wb in
            Writer<W, any Publisher<C, E>>(
                AnyPublisher<C, E>.liftA2(fn)(wa.value, wb.value),
                W.combine(wa.log, wb.log)
            )
        }
    }

    /// seqRight for Writer<W, Publisher>
    @available(macOS 13.0, iOS 16.0, tvOS 16.0, watchOS 9.0, *)
    func seqRightWriterPublisher<W: Monoid, A, B, E: Error>(
        _ lhs: Writer<W, any Publisher<A, E>>,
        _ rhs: Writer<W, any Publisher<B, E>>
    ) -> Writer<W, any Publisher<B, E>> {
        Writer<W, any Publisher<B, E>>(
            AnyPublisher<B, E>.seqRight(lhs.value, rhs.value),
            W.combine(lhs.log, rhs.log)
        )
    }

    /// seqLeft for Writer<W, Publisher>
    @available(macOS 13.0, iOS 16.0, tvOS 16.0, watchOS 9.0, *)
    func seqLeftWriterPublisher<W: Monoid, A, B, E: Error>(
        _ lhs: Writer<W, any Publisher<A, E>>,
        _ rhs: Writer<W, any Publisher<B, E>>
    ) -> Writer<W, any Publisher<A, E>> {
        Writer<W, any Publisher<A, E>>(
            AnyPublisher<A, E>.seqLeft(lhs.value, rhs.value),
            W.combine(lhs.log, rhs.log)
        )
    }

#endif
