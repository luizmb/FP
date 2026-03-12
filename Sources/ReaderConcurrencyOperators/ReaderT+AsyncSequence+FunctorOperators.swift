import Foundation
import FP
import Reader
import ConcurrencyFP
import ReaderConcurrencyFP
import Operators
import ConcurrencyOperators

// ReaderT + AsyncSequence

// (<$>) :: Functor f => (a -> b) -> f a -> f b
@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public func <£> <A, B, Env>(_ transform: @escaping @Sendable (A) -> B, _ reader: Reader<Env, AsyncStream<A>>)
-> Reader<Env, AsyncMapSequence<AsyncStream<A>, B>> {
    reader.mapT(transform)
}

// ($>) :: f a -> b -> f b
@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public func £> <A, B, Env>(_ reader: Reader<Env, AsyncStream<A>>, _ value: B)
-> Reader<Env, AsyncMapSequence<AsyncStream<A>, B>> where B: Sendable {
    reader.mapT { _ in value }
}

// (<$) :: a -> f b -> f a
@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public func <£ <A, B, Env>(_ value: A, _ reader: Reader<Env, AsyncStream<B>>)
-> Reader<Env, AsyncMapSequence<AsyncStream<B>, A>> where A: Sendable {
    reader £> value
}
