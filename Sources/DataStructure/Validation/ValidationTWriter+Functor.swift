// SPDX-License-Identifier: Apache-2.0
import CoreFP

/// ValidationTWriter: outer = Validation, inner = Writer
/// Type: Validation<E, Writer<W, A>>

public func mapTValidationWriter<E: Semigroup, W: Monoid, A, B>(
    _ fn: @escaping @Sendable (A) -> B
) -> (Validation<E, Writer<W, A>>) -> Validation<E, Writer<W, B>> {
    { $0.mapSuccess { writer in writer.map(fn) } }
}
