// SPDX-License-Identifier: Apache-2.0
import CoreFP
import CoreFPOperators
import DataStructure
import Foundation

/// (<$>) :: (a -> b) -> Stateful<s, a> -> Stateful<s, b>
public func <£> <S: Sendable, A: Sendable, B: Sendable>(
    _ transform: @escaping @Sendable (A) -> B,
    _ stateful: Stateful<S, A>
) -> Stateful<S, B> {
    stateful.map(transform)
}

/// ($>) :: Stateful<s, a> -> b -> Stateful<s, b>
public func £> <S: Sendable, A: Sendable, B: Sendable>(
    _ stateful: Stateful<S, A>,
    _ value: B
) -> Stateful<S, B> {
    stateful.map(const(value))
}

/// (<$) :: b -> Stateful<s, a> -> Stateful<s, b>
public func <£ <S: Sendable, A: Sendable, B: Sendable>(
    _ value: B,
    _ stateful: Stateful<S, A>
) -> Stateful<S, B> {
    stateful £> value
}

/// (<&>) :: Stateful<s, a> -> (a -> b) -> Stateful<s, b>
public func <&> <S: Sendable, A: Sendable, B: Sendable>(
    _ stateful: Stateful<S, A>,
    _ transform: @escaping @Sendable (A) -> B
) -> Stateful<S, B> {
    stateful.mapStateful(transform)
}
