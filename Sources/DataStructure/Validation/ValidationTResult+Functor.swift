// SPDX-License-Identifier: Apache-2.0
import CoreFP

/// ValidationTResult: outer = Validation, inner = Result
/// Type: Validation<E, Result<A, Err>>

public func mapTValidationResult<E: Semigroup, A, B, Err: Error>(
    _ fn: @escaping @Sendable (A) -> B
) -> (Validation<E, Result<A, Err>>) -> Validation<E, Result<B, Err>> {
    { $0.mapSuccess { $0.map(fn) } }
}
