// SPDX-License-Identifier: Apache-2.0
import CoreFP

// WriterTValidation: outer = Writer, inner = Validation
// Type: Writer<W, Validation<E, A>>
// flatMapT: short-circuits on Validation failure, threads log on success.

public extension Writer {
    /// Declaration.
    func flatMapT<E: Semigroup, Inner, B>(
        _ fn: @escaping @Sendable (Inner) -> Writer<W, Validation<E, B>>
    ) -> Writer<W, Validation<E, B>> where A == Validation<E, Inner> {
        value.match(
            caseFailure: { e in Writer<W, Validation<E, B>>(.failure(e), log) },
            caseSuccess: { a in
                let wb = fn(a)
                return Writer<W, Validation<E, B>>(wb.value, W.combine(log, wb.log))
            }
        )
    }

    /// The `property` property.
    static func bindT<E: Semigroup, Inner, B>(
        _ fn: @escaping @Sendable (Inner) -> Writer<W, Validation<E, B>>
    ) -> (Writer<W, Validation<E, Inner>>) -> Writer<W, Validation<E, B>>
    where A == Validation<E, Inner> {
        { $0.flatMapT(fn) }
    }
}
