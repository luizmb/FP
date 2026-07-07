// SPDX-License-Identifier: Apache-2.0
import CoreFP
import CoreFPOperators
import DataStructure
import Foundation

/// (<$>) :: Functor f => (a -> b) -> f a -> f b
public func <£> <B1, A, B>(_ transform: @escaping @Sendable (B) -> B1, _ these: These<A, B>) -> These<A, B1> {
    These<A, B>.fmap(transform)(these)
}

/// ($>) :: These<A, B> -> b0 -> These<A, b0>
public func £> <B1, A, B>(_ these: These<A, B>, _ value: B1) -> These<A, B1> {
    these.match(
        caseThis: These.this,
        caseThat: const(These.that(value)),
        caseBoth: { a, _ in .both(a, value) }
    )
}

/// (<$) :: b0 -> These<A, B> -> These<A, b0>
public func <£ <B1, A, B>(_ value: B1, _ these: These<A, B>) -> These<A, B1> {
    these £> value
}
