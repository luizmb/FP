// SPDX-License-Identifier: Apache-2.0
import CoreFP

// ValidationTResult: outer = Validation, inner = Result
// Type: Validation<E, Result<A, Err>>

extension Validation {
    /// Maps the value inside the inner Result, leaving `.failure` untouched.
    /// mapT :: (a -> b) -> Validation e (result a) -> Validation e (result b)
    func mapT<Inner, B, Err: Error>(_ fn: @escaping @Sendable (Inner) -> B) -> Validation<E, Result<B, Err>>
    where A == Result<Inner, Err> {
        mapSuccess { $0.map(fn) }
    }

    /// Curried, point-free form of ``mapT(_:)``.
    static func fmapT<Inner, B, Err: Error>(
        _ fn: @escaping @Sendable (Inner) -> B
    ) -> @Sendable (Validation<E, Result<Inner, Err>>) -> Validation<E, Result<B, Err>>
    where A == Result<Inner, Err> {
        { $0.mapT(fn) }
    }
}
