// SPDX-License-Identifier: Apache-2.0
import CoreFP
import CoreFPOperators
import DataStructure
import Foundation

// ReaderT + AsyncSequence

// (<$>) :: Functor f => (a -> b) -> f a -> f b
/// `func`.
@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public func <£^> <A, B, Env>(_ transform: @escaping @Sendable (A) -> B, _ reader: Reader<Env, AsyncStream<A>>)
-> Reader<Env, AsyncMapSequence<AsyncStream<A>, B>> {
    reader.mapT(transform)
}

// ($>) :: f a -> b -> f b
/// `£>` overload.
@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public func £> <A, B, Env>(_ reader: Reader<Env, AsyncStream<A>>, _ value: B)
-> Reader<Env, AsyncMapSequence<AsyncStream<A>, B>> where B: Sendable {
    reader.mapT(const(value))
}

// (<$) :: a -> f b -> f a
/// `func`.
@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public func <£ <A, B, Env>(_ value: A, _ reader: Reader<Env, AsyncStream<B>>)
-> Reader<Env, AsyncMapSequence<AsyncStream<B>, A>> where A: Sendable {
    reader £> value
}

// (<&^>) :: f (g a) -> (a -> b) -> f (g b)
/// `func`.
@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public func <&^> <A, B, Env>(_ reader: Reader<Env, AsyncStream<A>>, _ transform: @escaping @Sendable (A) -> B)
-> Reader<Env, AsyncMapSequence<AsyncStream<A>, B>> {
    transform <£^> reader
}
