// SPDX-License-Identifier: Apache-2.0
import CoreFP

public extension Result {
    /// traverse :: (a -> Either<l, c>) -> Result a e -> Either<l, Result c e>
    /// traverse _ (Failure e) = .right(.failure(e))
    /// traverse f (Success a) = fmap Success (f a)
    func traverse<L, C>(_ f: (Success) -> Either<L, C>) -> Either<L, Result<C, Failure>> {
        switch self {
        case let .failure(e):
            .right(.failure(e))

        case let .success(a):
            f(a).mapRight(Result<C, Failure>.success)
        }
    }

    /// sequence :: Result<Either<l, c>, e> -> Either<l, Result<c, e>>
    /// sequence = traverse id
    func sequence<L, C>() -> Either<L, Result<C, Failure>> where Success == Either<L, C> {
        traverse(CoreFP.id)
    }
}
