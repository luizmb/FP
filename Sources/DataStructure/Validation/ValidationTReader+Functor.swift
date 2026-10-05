// SPDX-License-Identifier: Apache-2.0
import CoreFP

// ValidationTReader: outer = Validation, inner = Reader
// Type: Validation<E, Reader<Env, A>>

extension Validation {
    /// Maps the value inside the inner Reader, leaving `.failure` untouched.
    /// mapT :: (a -> b) -> Validation e (reader a) -> Validation e (reader b)
    func mapT<Env, Inner, B>(_ fn: @escaping @Sendable (Inner) -> B) -> Validation<E, Reader<Env, B>>
    where A == Reader<Env, Inner> {
        mapSuccess { $0.mapReader(fn) }
    }

    /// Curried, point-free form of ``mapT(_:)``.
    static func fmapT<Env, Inner, B>(
        _ fn: @escaping @Sendable (Inner) -> B
    ) -> @Sendable (Validation<E, Reader<Env, Inner>>) -> Validation<E, Reader<Env, B>>
    where A == Reader<Env, Inner> {
        { $0.mapT(fn) }
    }
}
