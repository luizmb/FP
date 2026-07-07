// SPDX-License-Identifier: Apache-2.0
import CoreFP

/// ValidationTNonEmpty: outer = Validation, inner = NonEmpty
/// Type: Validation<E, NonEmpty<A>>

public func mapTValidationNonEmpty<E: Semigroup, A, B>(
    _ fn: @escaping @Sendable (A) -> B
) -> (Validation<E, NonEmpty<A>>) -> Validation<E, NonEmpty<B>> {
    { $0.mapSuccess { $0.map(fn) } }
}
