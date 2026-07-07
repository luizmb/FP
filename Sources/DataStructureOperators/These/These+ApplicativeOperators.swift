// SPDX-License-Identifier: Apache-2.0
import CoreFP
import CoreFPOperators
import DataStructure
import Foundation

/// (<*>) :: These<a, (b -> c)> -> These<a, b> -> These<a, c>
public func <*> <A: Semigroup, B, C>(_ lhs: These<A, @Sendable (B) -> C>, _ rhs: These<A, B>) -> These<A, C> {
    These<A, B>.apply(lhs, rhs)
}

/// (*>) :: These<a, ignore> -> These<a, b> -> These<a, b>
public func *> <A: Semigroup, Ignore: Sendable, B>(
    _ lhs: These<A, Ignore>,
    _ rhs: These<A, B>
) -> These<A, B> {
    lhs.seqRight(rhs)
}

/// (<*) :: These<a, b> -> These<a, ignore> -> These<a, b>
public func <* <A: Semigroup, B: Sendable, Ignore>(
    _ lhs: These<A, B>,
    _ rhs: These<A, Ignore>
) -> These<A, B> {
    lhs.seqLeft(rhs)
}
