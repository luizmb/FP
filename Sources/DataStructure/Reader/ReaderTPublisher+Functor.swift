#if canImport(Combine)
import Foundation
import CoreFP
import Combine

public extension Reader {
    // ReaderT + Publisher
    @available(macOS 13.0, iOS 16.0, tvOS 16.0, watchOS 9.0, *)
    func mapT<A, B, E: Error>(_ fn: @escaping (A) -> B) -> Reader<Environment, any Publisher<B, E>>
    where Output == any Publisher<A, E>, A: Sendable {
        mapReader(AnyPublisher<A, E>.fmap(fn))
    }

    @available(macOS 13.0, iOS 16.0, tvOS 16.0, watchOS 9.0, *)
    static func fmap<A, B, E: Error>(
        _ fn: @escaping (A) -> B
    ) -> (Reader<Environment, any Publisher<A, E>>) -> Reader<Environment, any Publisher<B, E>>
    where A: Sendable, Output == any Publisher<A, E> {
        { $0.mapT(fn) }
    }

    /// replaceOutputT :: Reader<e, Publisher<a, err>> -> b -> Reader<e, Publisher<b, err>>
    @available(macOS 13.0, iOS 16.0, tvOS 16.0, watchOS 9.0, *)
    func replaceOutputT<A, B, E: Error>(_ value: B) -> Reader<Environment, any Publisher<B, E>>
    where Output == any Publisher<A, E> {
        mapReader { $0.eraseToAnyPublisher().map(const(value)).eraseToAnyPublisher() }
    }
}

#endif
