// SPDX-License-Identifier: Apache-2.0
// swiftlint:disable discouraged_optional_collection
import CoreFP

// OptionalTArray: outer = Optional, inner = Array
// Type: [A]? = Optional<[A]>

/// (>>-) :: [a]? -> (a -> [b]?) -> [b]?
public func >>- <A, B>(_ opt: [A]?, _ fn: @escaping @Sendable (A) -> [B]?) -> [B]? {
    opt.flatMapT(fn)
}

/// (-<<) :: (a -> [b]?) -> [a]? -> [b]?
public func -<< <A, B>(_ fn: @escaping @Sendable (A) -> [B]?, _ opt: [A]?) -> [B]? {
    opt.flatMapT(fn)
}

/// (>=>) :: (a -> [b]?) -> (b -> [c]?) -> a -> [c]?
public func >=> <A, B, C>(_ fn1: @escaping @Sendable (A) -> [B]?, _ fn2: @escaping @Sendable (B) -> [C]?) -> (A) -> [C]? {
    kleisliT(fn1, fn2)
}

// swiftlint:enable discouraged_optional_collection
