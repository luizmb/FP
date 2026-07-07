// SPDX-License-Identifier: Apache-2.0
import CoreFP

/// ValidationTArray: outer = Validation, inner = Array
/// Type: Validation<E, [A]>

public func mapTValidationArray<E: Semigroup, A, B>(
    _ fn: @escaping @Sendable (A) -> B
) -> (Validation<E, [A]>) -> Validation<E, [B]> {
    { $0.mapSuccess { $0.map(fn) } }
}
