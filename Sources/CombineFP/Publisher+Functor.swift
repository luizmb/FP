#if canImport(Combine)
import Combine
import Foundation
import FP

#if canImport(Operators)
import Operators
// (<$>) :: Functor f => (a -> b) -> f a -> f b
@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public func <£> <A1, A, B: Error>(
    _ transform: @escaping (A) -> A1,
    _ publisher: any Publisher<A, B>
) -> any Publisher<A1, B> 
where B: Sendable, A1: Sendable, A: Sendable {
    Result<A1, B>.Publisher.fmap(transform)(publisher)
}

// ($>) :: Either a b -> a0 -> Either a a0
@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public func £> <A1, A, B: Error>(_ publisher: any Publisher<A, B>, _ value: A1) -> any Publisher<A1, B> {
    publisher.eraseToAnyPublisher().map(const(value))
}

// (<$) :: a0 -> Either a b -> Either a a0
@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public func <£ <A1, A, B: Error>(_ value: A1, _ publisher: any Publisher<A, B>) -> any Publisher<A1, B> {
    publisher £> value
}
#endif

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public extension Publisher {
    typealias A = Output
    typealias B = Failure

    static func left(_ a: A) -> any Publisher {
        Result<A, B>.success(a).publisher
    }

    static func right(_ b: B) -> any Publisher {
        Result<A, B>.failure(b).publisher
    }

    static func fmap<A0>(
        _ fn: @escaping (A0) -> A
    ) -> (any Publisher<A0, Failure>) -> any Publisher<A, Failure> {
        { previous in previous.eraseToAnyPublisher().map(fn) }
    }

    func mapLeft<A1>(
        _ lf: @escaping (Output) -> A1
    ) -> any Publisher<A1, Failure> {
        map(lf)
    }

    func mapRight<B1: Error>(
        _ rf: @escaping (B) -> B1
    ) -> any Publisher<A, B1> {
        mapError(rf)
    }

    func bimap<A1, B1: Error>(
        _ lf: @escaping (A) -> A1,
        _ rf: @escaping (B) -> B1
    ) -> any Publisher<A1, B1> {
        map(lf)
            .mapError(rf)
    }
}

#endif
