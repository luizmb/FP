// SPDX-License-Identifier: Apache-2.0
import CoreFP

// ReaderTValidation: outer = Reader, inner = Validation
// Type: Reader<Env, Validation<E, A>>
// flatMapT sequences — short-circuits on Validation failure (does NOT accumulate).

public extension Reader {
    /// Declaration.
    func flatMapT<E: Semigroup, Inner, B>(
        _ fn: @escaping @Sendable (Inner) -> Reader<Environment, Validation<E, B>>
    ) -> Reader<Environment, Validation<E, B>>
    where Output == Validation<E, Inner> {
        Reader<Environment, Validation<E, B>> { env in
            self(env).match(
                caseFailure: Validation.failure,
                caseSuccess: { a in fn(a)(env) }
            )
        }
    }

    /// The `property` property.
    static func bindT<E: Semigroup, Inner, B>(
        _ fn: @escaping @Sendable (Inner) -> Reader<Environment, Validation<E, B>>
    ) -> (Reader<Environment, Validation<E, Inner>>) -> Reader<Environment, Validation<E, B>>
    where Output == Validation<E, Inner> {
        { $0.flatMapT(fn) }
    }
}
