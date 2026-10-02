// SPDX-License-Identifier: Apache-2.0
#if canImport(Combine)
    import Combine
    import Foundation

    /// First-success: if lhs fails, switch to rhs.
    /// alt :: Publisher a -> Publisher a -> Publisher a
    ///
    /// `rhs` is only built when `lhs` fails (once per failing subscription).
    @available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
    public func altPublisher<A, E: Error>(
        _ lhs: any Publisher<A, E>,
        _ rhs: @autoclosure @escaping () -> any Publisher<A, E>
    ) -> any Publisher<A, E> {
        lhs.eraseToAnyPublisher()
            .catch { (_: E) in rhs().eraseToAnyPublisher() }
            .eraseToAnyPublisher()
    }

#endif
