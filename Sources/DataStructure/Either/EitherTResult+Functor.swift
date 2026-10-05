// SPDX-License-Identifier: Apache-2.0
import CoreFP

// EitherTResult: outer = Either, inner = Result
// Type: Either<L, Result<A, E>>

extension Either {
    /// Maps the value inside the inner Result, leaving `.left` untouched.
    /// mapT :: (a -> b) -> Either l (result a) -> Either l (result b)
    func mapT<Inner, C, E: Error>(_ fn: @escaping @Sendable (Inner) -> C) -> Either<A, Result<C, E>>
    where B == Result<Inner, E> {
        mapRight { $0.map(fn) }
    }

    /// Curried, point-free form of ``mapT(_:)``.
    static func fmapT<Inner, C, E: Error>(
        _ fn: @escaping @Sendable (Inner) -> C
    ) -> @Sendable (Either<A, Result<Inner, E>>) -> Either<A, Result<C, E>>
    where B == Result<Inner, E> {
        { $0.mapT(fn) }
    }
}
