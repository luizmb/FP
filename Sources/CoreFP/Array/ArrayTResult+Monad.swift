// SPDX-License-Identifier: Apache-2.0
import Foundation

// ArrayTResult: outer = Array, inner = Result
// Type: [Result<A,E>] = Array<Result<A,E>>
// Haskell: ExceptT e []

public extension Array {
    /// flatMapT for [Result<A,E>]
    /// (>>=) :: [Result<a,e>] -> (a -> [Result<b,e>]) -> [Result<b,e>]
    /// For each element: .failure(e) → [.failure(e)], .success(a) → fn(a)
    func flatMapT<A, B, E: Error>(_ fn: @escaping @Sendable (A) -> [Result<B, E>]) -> [Result<B, E>]
    where Element == Result<A, E> {
        bindArrayResult(self, fn)
    }

    /// Curried bindT for [Result<A,E>]
    static func bindT<A, B, E: Error>(
        _ fn: @escaping @Sendable (A) -> [Result<B, E>]
    ) -> @Sendable ([Result<A, E>]) -> [Result<B, E>] {
        { arr in arr.flatMapT(fn) }
    }
}

/// The `ExceptT e []` bind, shared by ``Array/flatMapT(_:)`` and the applicative surface
/// (`applyArrayResult`, `liftA2ArrayResult`, `seqRightArrayResult`, `seqLeftArrayResult`),
/// so `<*>` = `ap` holds by construction. Non-escaping, so callers may capture non-`Sendable` values.
/// .failure(e) → [.failure(e)], .success(a) → fn(a)
func bindArrayResult<A, B, E: Error>(_ arr: [Result<A, E>], _ fn: (A) -> [Result<B, E>]) -> [Result<B, E>] {
    arr.flatMap { result -> [Result<B, E>] in
        switch result {
        case let .failure(e):
            [.failure(e)]

        case let .success(a):
            fn(a)
        }
    }
}

/// Kleisli composition for `ArrayT + Result` (left-to-right)
/// (>=>) :: (a -> [Result<b,e>]) -> (b -> [Result<c,e>]) -> a -> [Result<c,e>]
public func kleisliT<A, B, C, E: Error>(
    _ fn1: @escaping @Sendable (A) -> [Result<B, E>],
    _ fn2: @escaping @Sendable (B) -> [Result<C, E>]
) -> @Sendable (A) -> [Result<C, E>] {
    { a in fn1(a).flatMapT(fn2) }
}
