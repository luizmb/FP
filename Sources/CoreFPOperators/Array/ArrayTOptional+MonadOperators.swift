// SPDX-License-Identifier: Apache-2.0
import CoreFP

// ArrayTOptional: outer = Array, inner = Optional
// Type: [A?] = Array<Optional<A>>

/// (>>-) :: [a?] -> (a -> [b?]) -> [b?]
public func >>- <A, B>(_ arr: [A?], _ fn: @escaping @Sendable (A) -> [B?]) -> [B?] {
    arr.flatMapT(fn)
}

/// (-<<) :: (a -> [b?]) -> [a?] -> [b?]
public func -<< <A, B>(_ fn: @escaping @Sendable (A) -> [B?], _ arr: [A?]) -> [B?] {
    arr.flatMapT(fn)
}

/// (>=>) :: (a -> [b?]) -> (b -> [c?]) -> a -> [c?]
public func >=> <A, B, C>(_ fn1: @escaping @Sendable (A) -> [B?], _ fn2: @escaping @Sendable (B) -> [C?]) -> (A) -> [C?] {
    { a in fn1(a).flatMapT(fn2) }
}
