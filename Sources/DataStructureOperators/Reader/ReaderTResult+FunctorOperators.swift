// SPDX-License-Identifier: Apache-2.0
import CoreFPOperators
import DataStructure
import Foundation

// ReaderT + Result

/// (<$>) :: Functor f => (a -> b) -> f a -> f b
public func <£^> <A: Sendable, B: Sendable, E: Error, Env: Sendable>(
    _ transform: @escaping @Sendable (A) -> B,
    _ reader: Reader<Env, Result<A, E>>
) -> Reader<Env, Result<B, E>> {
    reader.mapT(transform)
}

/// ($>) :: f a -> b -> f b
public func £> <A1: Sendable, A: Sendable, B: Sendable, Env: Sendable>(
    _ reader: Reader<Env, Result<A, B>>,
    _ value: A1
) -> Reader<Env, Result<A1, B>> {
    reader.replaceOutputT(value)
}

/// (<$) :: a -> f b -> f a
public func <£ <A1: Sendable, A: Sendable, B: Sendable, Env: Sendable>(
    _ value: A1,
    _ reader: Reader<Env, Result<A, B>>
) -> Reader<Env, Result<A1, B>> {
    reader £> value
}

/// (<&^>) :: f (g a) -> (a -> b) -> f (g b)
public func <&^> <A: Sendable, B: Sendable, E: Error, Env: Sendable>(
    _ reader: Reader<Env, Result<A, E>>,
    _ transform: @escaping @Sendable (A) -> B
) -> Reader<Env, Result<B, E>> {
    transform <£^> reader
}
