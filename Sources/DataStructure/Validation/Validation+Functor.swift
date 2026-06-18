// SPDX-License-Identifier: Apache-2.0
import CoreFP

public extension Validation {
    /// The `property` property.
    static func fmap<B>(_ fn: @escaping @Sendable (A) -> B) -> @Sendable (Validation<E, A>) -> Validation<E, B> {
        { $0.mapSuccess(fn) }
    }

    /// Declaration.
    func mapSuccess<B>(_ fn: @escaping @Sendable (A) -> B) -> Validation<E, B> {
        match(
            caseFailure: Validation<E, B>.failure,
            caseSuccess: compose(fn, Validation<E, B>.success)
        )
    }

    /// Declaration.
    func mapFailure<E1: Semigroup>(_ fn: @escaping @Sendable (E) -> E1) -> Validation<E1, A> {
        match(
            caseFailure: compose(fn, Validation<E1, A>.failure),
            caseSuccess: Validation<E1, A>.success
        )
    }

    /// Declaration.
    func bimap<E1: Semigroup, B>(_ ef: @escaping @Sendable (E) -> E1, _ af: @escaping @Sendable (A) -> B) -> Validation<E1, B> {
        match(
            caseFailure: compose(ef, Validation<E1, B>.failure),
            caseSuccess: compose(af, Validation<E1, B>.success)
        )
    }

    /// Declaration.
    func void() -> Validation<E, Void> {
        mapSuccess(ignore)
    }

    /// The `property` property.
    static func bimap<E1: Semigroup, B>(
        _ ef: @escaping @Sendable (E) -> E1,
        _ af: @escaping @Sendable (A) -> B
    ) -> (Validation<E, A>) -> Validation<E1, B> {
        { $0.bimap(ef, af) }
    }
}
