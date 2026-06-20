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
        flatMap { result -> [Result<B, E>] in
            switch result {
            case let .failure(e):
                [.failure(e)]

            case let .success(a):
                fn(a)
            }
        }
    }

    /// Curried bindT for [Result<A,E>]
    static func bindT<A, B, E: Error>(
        _ fn: @escaping @Sendable (A) -> [Result<B, E>]
    ) -> ([Result<A, E>]) -> [Result<B, E>] {
        { arr in arr.flatMapT(fn) }
    }
}
