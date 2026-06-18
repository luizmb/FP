// SPDX-License-Identifier: Apache-2.0
#if canImport(Combine)
    import Combine
    import CoreFP

    // (<|>) :: Publisher a -> Publisher a -> Publisher a
    // First-success: if lhs fails, switch to rhs.
    /// `func`.
    @available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
    public func <|> <A, E: Error>(
        _ lhs: any Publisher<A, E>,
        _ rhs: @autoclosure () -> any Publisher<A, E>
    ) -> any Publisher<A, E> {
        altPublisher(lhs, rhs())
    }

#endif
