// SPDX-License-Identifier: Apache-2.0
import CoreFP

public extension Result {
    /// traverse :: (a -> Validation<e2, c>) -> Result a e -> Validation<e2, Result c e>
    /// traverse _ (Failure e) = .success(.failure(e))
    /// traverse f (Success a) = fmap Success (f a)
    func traverse<E2: Semigroup, C>(_ f: (Success) -> Validation<E2, C>) -> Validation<E2, Result<C, Failure>> {
        switch self {
        case let .failure(e):
            .success(.failure(e))

        case let .success(a):
            f(a).mapSuccess(Result<C, Failure>.success)
        }
    }

    /// sequence :: Result<Validation<e2, c>, e> -> Validation<e2, Result<c, e>>
    /// sequence = traverse id
    func sequence<E2: Semigroup, C>() -> Validation<E2, Result<C, Failure>> where Success == Validation<E2, C> {
        traverse(CoreFP.id)
    }
}
