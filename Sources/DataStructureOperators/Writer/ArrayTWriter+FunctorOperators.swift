// SPDX-License-Identifier: Apache-2.0
import CoreFP
import CoreFPOperators
import DataStructure

/// (<£^>) :: (a -> b) -> [Writer<w, a>] -> [Writer<w, b>]
public func <£^> <W: Monoid, A, B>(_ fn: @escaping @Sendable (A) -> B, _ arr: [Writer<W, A>]) -> [Writer<W, B>] {
    arr.mapT(fn)
}

/// (<&^>) :: [Writer<w, a>] -> (a -> b) -> [Writer<w, b>]
public func <&^> <W: Monoid, A, B>(_ arr: [Writer<W, A>], _ fn: @escaping @Sendable (A) -> B) -> [Writer<W, B>] {
    arr.mapT(fn)
}
