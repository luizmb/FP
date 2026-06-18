// SPDX-License-Identifier: Apache-2.0
import CoreFP
import CoreFPOperators
import DataStructure
import Foundation

/// (<$>) :: Functor f => (a -> b) -> f a -> f b
public func <£> <Env: Sendable, A: Sendable, B: Sendable>(
    _ transform: @escaping @Sendable (A) -> B,
    _ reader: Reader<Env, A>
) -> Reader<Env, B> {
    reader.map(transform)
}

/// ($>) :: f a -> b -> f b
public func £> <Env: Sendable, A: Sendable, B: Sendable>(
    _ reader: Reader<Env, A>,
    _ value: B
) -> Reader<Env, B> {
    reader.map(const(value))
}

/// (<$) :: b -> f a -> f b
public func <£ <Env: Sendable, A: Sendable, B: Sendable>(
    _ value: B,
    _ reader: Reader<Env, A>
) -> Reader<Env, B> {
    reader £> value
}
