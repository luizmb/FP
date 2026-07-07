// SPDX-License-Identifier: Apache-2.0
import Foundation

// OptionalTResult: outer = Optional, inner = Result
// Type: Result<A,E>? = Optional<Result<A,E>>
// Haskell: ExceptT e Maybe

public extension Optional {
    /// flatMapT for Optional<Result<A,E>>
    /// (>>=) :: Result<a,e>? -> (a -> Result<b,e>?) -> Result<b,e>?
    /// nil       → nil
    /// .failure  → .some(.failure(e))
    /// .success  → fn(a)
    func flatMapT<A, B, E: Error>(_ fn: @escaping @Sendable (A) -> Result<B, E>?) -> Result<B, E>? where Wrapped == Result<A, E> {
        flatMap { result in
            switch result {
            case let .failure(e):
                .some(.failure(e))

            case let .success(a):
                fn(a)
            }
        }
    }

    /// Curried bindT for Optional<Result<A,E>>
    static func bindT<A, B, E: Error>(_ fn: @escaping @Sendable (A) -> Result<B, E>?) -> @Sendable (Result<A, E>?) -> Result<B, E>? {
        { opt in opt.flatMapT(fn) }
    }
}

/// Kleisli composition for `OptionalT + Result` (left-to-right)
/// (>=>) :: (a -> Result<b,e>?) -> (b -> Result<c,e>?) -> a -> Result<c,e>?
public func kleisliT<A, B, C, E: Error>(
    _ fn1: @escaping @Sendable (A) -> Result<B, E>?,
    _ fn2: @escaping @Sendable (B) -> Result<C, E>?
) -> (A) -> Result<C, E>? {
    { a in fn1(a).flatMapT(fn2) }
}
