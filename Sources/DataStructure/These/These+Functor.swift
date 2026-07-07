// SPDX-License-Identifier: Apache-2.0
import CoreFP
import Foundation

public extension These {
    /// The `property` property.
    static func fmap<B1>(
        _ fn: @escaping @Sendable (B) -> B1
    ) -> @Sendable (These<A, B>) -> These<A, B1> {
        { $0.map(fn) }
    }

    /// Declaration.
    func map<B1>(
        _ fn: @escaping @Sendable (B) -> B1
    ) -> These<A, B1> {
        match(
            caseThis: These<A, B1>.this,
            caseThat: compose(fn, These<A, B1>.that),
            caseBoth: { a, b in .both(a, fn(b)) }
        )
    }

    /// Declaration.
    func mapThis<A1>(
        _ fn: @escaping @Sendable (A) -> A1
    ) -> These<A1, B> {
        match(
            caseThis: compose(fn, These<A1, B>.this),
            caseThat: These<A1, B>.that,
            caseBoth: { a, b in .both(fn(a), b) }
        )
    }

    /// The `property` property.
    static func mapThis<A1>(
        _ fn: @escaping @Sendable (A) -> A1
    ) -> (These<A, B>) -> These<A1, B> {
        { $0.mapThis(fn) }
    }

    /// Declaration.
    func bimap<A1, B1>(
        _ lf: @escaping @Sendable (A) -> A1,
        _ rf: @escaping @Sendable (B) -> B1
    ) -> These<A1, B1> {
        match(
            caseThis: compose(lf, These<A1, B1>.this),
            caseThat: compose(rf, These<A1, B1>.that),
            caseBoth: { a, b in .both(lf(a), rf(b)) }
        )
    }

    /// The `property` property.
    static func bimap<A1, B1>(
        _ lf: @escaping @Sendable (A) -> A1,
        _ rf: @escaping @Sendable (B) -> B1
    ) -> (These<A, B>) -> These<A1, B1> {
        { $0.bimap(lf, rf) }
    }
}
