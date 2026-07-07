// SPDX-License-Identifier: Apache-2.0
import CoreFPOperators
import DataStructure

// OptionalTNonEmpty: outer = Optional, inner = NonEmpty
// Type: NonEmpty<A>? = Optional<NonEmpty<A>>

/// (>>-) :: NonEmpty<A>? -> (A -> NonEmpty<B>?) -> NonEmpty<B>?
public func >>- <A, B>(_ opt: NonEmpty<A>?, _ fn: @escaping @Sendable (A) -> NonEmpty<B>?) -> NonEmpty<B>? {
    opt.flatMapT(fn)
}

/// (-<<) :: (A -> NonEmpty<B>?) -> NonEmpty<A>? -> NonEmpty<B>?
public func -<< <A, B>(_ fn: @escaping @Sendable (A) -> NonEmpty<B>?, _ opt: NonEmpty<A>?) -> NonEmpty<B>? {
    opt.flatMapT(fn)
}

/// (>=>) :: (A -> NonEmpty<B>?) -> (B -> NonEmpty<C>?) -> A -> NonEmpty<C>?
public func >=> <A, B, C>(
    _ fn1: @escaping @Sendable (A) -> NonEmpty<B>?,
    _ fn2: @escaping @Sendable (B) -> NonEmpty<C>?
) -> (A) -> NonEmpty<C>? {
    kleisliT(fn1, fn2)
}

/// (<=<) :: (B -> NonEmpty<C>?) -> (A -> NonEmpty<B>?) -> A -> NonEmpty<C>?
public func <=< <A, B, C>(
    _ fn2: @escaping @Sendable (B) -> NonEmpty<C>?,
    _ fn1: @escaping @Sendable (A) -> NonEmpty<B>?
) -> (A) -> NonEmpty<C>? {
    fn1 >=> fn2
}
