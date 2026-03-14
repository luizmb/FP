#if canImport(Combine)
import Combine
import Foundation
import FP

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

    static func fmap<A1>(
        _ fn: @escaping (A) -> A1
    ) -> (any Publisher<A, Failure>) -> any Publisher<A1, Failure> {
        { $0.eraseToAnyPublisher().map(fn) }
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

    /// replaceOutput :: Publisher<a, e> -> b -> Publisher<b, e>
    func replaceOutput<A1>(_ value: A1) -> any Publisher<A1, Failure> {
        eraseToAnyPublisher().map { _ in value }
    }
}

#endif
