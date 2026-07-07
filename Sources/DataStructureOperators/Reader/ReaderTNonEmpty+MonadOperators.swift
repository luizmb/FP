// SPDX-License-Identifier: Apache-2.0
import CoreFPOperators
import DataStructure
import Foundation

// ReaderTNonEmpty: outer = Reader, inner = NonEmpty
// Type: Reader<Environment, NonEmpty<A>>

/// (>>-) :: Reader<Env, NonEmpty<A>> -> (A -> Reader<Env, NonEmpty<B>?>) -> Reader<Env, NonEmpty<B>?>
public func >>- <Env, A, B>(
    _ reader: Reader<Env, NonEmpty<A>>,
    _ fn: @escaping @Sendable (A) -> Reader<Env, NonEmpty<B>?>
) -> Reader<Env, NonEmpty<B>?> {
    reader.flatMapT(fn)
}

/// (-<<) :: (A -> Reader<Env, NonEmpty<B>?>) -> Reader<Env, NonEmpty<A>> -> Reader<Env, NonEmpty<B>?>
public func -<< <Env, A, B>(
    _ fn: @escaping @Sendable (A) -> Reader<Env, NonEmpty<B>?>,
    _ reader: Reader<Env, NonEmpty<A>>
) -> Reader<Env, NonEmpty<B>?> {
    reader.flatMapT(fn)
}

/// (>=>) :: (A -> Reader<Env, NonEmpty<B>?>) -> (B -> Reader<Env, NonEmpty<C>?>) -> A -> Reader<Env, NonEmpty<C>?>
public func >=> <Env, A, B, C>(
    _ fn1: @escaping @Sendable (A) -> Reader<Env, NonEmpty<B>?>,
    _ fn2: @escaping @Sendable (B) -> Reader<Env, NonEmpty<C>?>
) -> (A) -> Reader<Env, NonEmpty<C>?> {
    kleisliT(fn1, fn2)
}
