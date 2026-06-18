// SPDX-License-Identifier: Apache-2.0
import CoreFP

public extension Validation {
    /// traverse :: (a -> Result<b, e2>) -> Validation e a -> Result<Validation e b, e2>
    /// traverse _ (Failure e) = .success(.failure(e))
    /// traverse f (Success a) = fmap Success (f a)
    func traverse<B, E2: Error>(_ f: (A) -> Result<B, E2>) -> Result<Validation<E, B>, E2> {
        match(
            caseFailure: { .success(.failure($0)) },
            caseSuccess: { f($0).map(Validation<E, B>.success) }
        )
    }

    /// sequence :: Validation e (Result<b, e2>) -> Result<Validation e b, e2>
    /// sequence = traverse id
    func sequence<B, E2: Error>() -> Result<Validation<E, B>, E2> where A == Result<B, E2> {
        traverse(CoreFP.id)
    }
}
