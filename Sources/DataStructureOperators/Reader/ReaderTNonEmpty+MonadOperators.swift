// SPDX-License-Identifier: Apache-2.0
import CoreFPOperators
import DataStructure

// ReaderTNonEmpty: outer = Reader, inner = NonEmpty
// Type: Reader<Environment, NonEmpty<A>>

/// (>>-) :: Reader<env, NonEmpty<a>> -> (a -> Reader<env, NonEmpty<b>>) -> Reader<env, NonEmpty<b>>
public func >>- <Env, A, B>(
    _ reader: Reader<Env, NonEmpty<A>>,
    _ fn: @escaping @Sendable (A) -> Reader<Env, NonEmpty<B>>
) -> Reader<Env, NonEmpty<B>> {
    reader.flatMapT(fn)
}

/// (-<<) :: (a -> Reader<env, NonEmpty<b>>) -> Reader<env, NonEmpty<a>> -> Reader<env, NonEmpty<b>>
public func -<< <Env, A, B>(
    _ fn: @escaping @Sendable (A) -> Reader<Env, NonEmpty<B>>,
    _ reader: Reader<Env, NonEmpty<A>>
) -> Reader<Env, NonEmpty<B>> {
    reader.flatMapT(fn)
}

/// (>=>) :: (a -> Reader<env, NonEmpty<b>>) -> (b -> Reader<env, NonEmpty<c>>) -> a -> Reader<env, NonEmpty<c>>
public func >=> <Env, A, B, C>(
    _ fn1: @escaping @Sendable (A) -> Reader<Env, NonEmpty<B>>,
    _ fn2: @escaping @Sendable (B) -> Reader<Env, NonEmpty<C>>
) -> @Sendable (A) -> Reader<Env, NonEmpty<C>> {
    kleisliT(fn1, fn2)
}
