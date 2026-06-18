// SPDX-License-Identifier: Apache-2.0
import CoreFP

/// ValidationTReader: outer = Validation, inner = Reader
/// Type: Validation<E, Reader<Env, A>>

public func fmapTValidationReader<E: Semigroup, Env, A, B>(
    _ fn: @escaping @Sendable (A) -> B
) -> (Validation<E, Reader<Env, A>>) -> Validation<E, Reader<Env, B>> {
    { $0.mapSuccess { reader in reader.mapReader(fn) } }
}
