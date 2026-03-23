#if canImport(Combine)
import Combine
import Foundation

/// First-success: if lhs fails, switch to rhs.
/// alt :: Publisher a -> Publisher a -> Publisher a
@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public func altPublisher<A, E: Error>(
    _ lhs: any Publisher<A, E>,
    _ rhs: @autoclosure () -> any Publisher<A, E>
) -> any Publisher<A, E> {
    let captured = rhs()
    return lhs.eraseToAnyPublisher()
        .catch { (_: E) in captured.eraseToAnyPublisher() }
        .eraseToAnyPublisher()
}

#endif
