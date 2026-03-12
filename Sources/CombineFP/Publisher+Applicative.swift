#if canImport(Combine)
import Combine
import FP
import Foundation

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public extension Publisher {
    // liftA2 :: (b1 -> b2 -> b) -> Either a b1 -> Either a b2 -> Either a b
    static func liftA2<A1, A2>(_ fn: @escaping (A1, A2) -> A) -> (
        any Publisher<A1, B>, any Publisher<A2, B>
    ) -> any Publisher<A, B> {
        { publisherA, publisherB in
            publisherA
                .eraseToAnyPublisher()
                .zip(publisherB.eraseToAnyPublisher())
                .map(fn)
        }
    }

    static func zip<A1, A2>(_ lhs: any Publisher<A1, B>, _ rhs: any Publisher<A2, B>) -> any Publisher<A, B>
    where A == (A1, A2) {
        Publishers.Zip(lhs.eraseToAnyPublisher(), rhs.eraseToAnyPublisher())
    }
}

#endif
