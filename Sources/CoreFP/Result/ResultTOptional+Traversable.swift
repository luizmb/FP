// SPDX-License-Identifier: Apache-2.0
public extension Result {
    /// traverse :: (a -> b?) -> Result a e -> (Result b e)?
    /// traverse _ (Failure e) = .some(.failure(e))
    /// traverse f (Success a) = fmap Success (f a)
    func traverse<B>(_ f: (Success) -> B?) -> Result<B, Failure>? {
        switch self {
        case let .failure(e):
            .some(.failure(e))

        case let .success(a):
            f(a).map(Result<B, Failure>.success)
        }
    }

    /// sequence :: Result<b?, e> -> (Result<b, e>)?
    /// sequence = traverse id
    func sequence<B>() -> Result<B, Failure>? where Success == B? {
        traverse(CoreFP.id)
    }
}
