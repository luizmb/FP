// SPDX-License-Identifier: Apache-2.0
import CoreFPOperators
import DataStructure

// ReaderTStateful: outer = Reader, inner = Stateful
// Type: Reader<Env, Stateful<S, A>>

/// (>>-) :: Reader<env, Stateful<s, a>> -> (a -> Reader<env, Stateful<s, b>>) -> Reader<env, Stateful<s, b>>
public func >>- <Env: Sendable, S, A, B>(
    _ reader: Reader<Env, Stateful<S, A>>,
    _ fn: @escaping @Sendable (A) -> Reader<Env, Stateful<S, B>>
) -> Reader<Env, Stateful<S, B>> {
    reader.flatMapT(fn)
}

/// (-<<) :: (a -> Reader<env, Stateful<s, b>>) -> Reader<env, Stateful<s, a>> -> Reader<env, Stateful<s, b>>
public func -<< <Env: Sendable, S, A, B>(
    _ fn: @escaping @Sendable (A) -> Reader<Env, Stateful<S, B>>,
    _ reader: Reader<Env, Stateful<S, A>>
) -> Reader<Env, Stateful<S, B>> {
    reader.flatMapT(fn)
}

/// (>=>) :: (a -> Reader<env, Stateful<s, b>>) -> (b -> Reader<env, Stateful<s, c>>) -> a -> Reader<env, Stateful<s, c>>
public func >=> <Env: Sendable, S, A, B, C>(
    _ fn1: @escaping @Sendable (A) -> Reader<Env, Stateful<S, B>>,
    _ fn2: @escaping @Sendable (B) -> Reader<Env, Stateful<S, C>>
) -> @Sendable (A) -> Reader<Env, Stateful<S, C>> {
    kleisliT(fn1, fn2)
}
