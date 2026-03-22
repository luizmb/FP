import DataStructure
#if canImport(Combine)
import Foundation
import CoreFP
import Combine
import CoreFPOperators

// ReaderT + Publisher

// (<$>) :: Functor f => (a -> b) -> f a -> f b
@available(macOS 13.0, iOS 16.0, tvOS 16.0, watchOS 9.0, *)
public func <£^> <A, B, E: Error, Env>(_ transform: @escaping (A) -> B, _ reader: Reader<Env, any Publisher<A, E>>)
-> Reader<Env, any Publisher<B, E>>
where A: Sendable, B: Sendable {
    reader.mapT(transform)
}

// ($>) :: Either a b -> a0 -> Either a a0
@available(macOS 13.0, iOS 16.0, tvOS 16.0, watchOS 9.0, *)
public func £> <A1, A, B: Error, Env>(_ reader: Reader<Env, any Publisher<A, B>>, _ value: A1)
-> Reader<Env, any Publisher<A1, B>> {
    reader.replaceOutputT(value)
}

// (<$) :: a0 -> Either a b -> Either a a0
@available(macOS 13.0, iOS 16.0, tvOS 16.0, watchOS 9.0, *)
public func <£ <A1, A, B: Error, Env>(_ value: A1, _ reader: Reader<Env, any Publisher<A, B>>)
-> Reader<Env, any Publisher<A1, B>> {
    reader £> value
}

#endif
