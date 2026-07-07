// SPDX-License-Identifier: Apache-2.0
import CoreFP
import CoreFPOperators
import DataStructure

// MARK: - Functor operators for Zipper

/// (<£>) :: (A -> B) -> Zipper<A> -> Zipper<B>
public func <£> <A, B>(
    _ fn: @escaping @Sendable (A) -> B,
    _ z: Zipper<A>
) -> Zipper<B> {
    z.map(fn)
}

/// ($>) :: Zipper<A> -> B -> Zipper<B>
public func £> <A, B>(
    _ z: Zipper<A>,
    _ value: B
) -> Zipper<B> {
    z.map(const(value))
}

/// (<$) :: B -> Zipper<A> -> Zipper<B>
public func <£ <A, B>(
    _ value: B,
    _ z: Zipper<A>
) -> Zipper<B> {
    z £> value
}

/// (<&>) :: Zipper<A> -> (A -> B) -> Zipper<B>
public func <&> <A, B>(
    _ z: Zipper<A>,
    _ fn: @escaping @Sendable (A) -> B
) -> Zipper<B> {
    z.map(fn)
}
