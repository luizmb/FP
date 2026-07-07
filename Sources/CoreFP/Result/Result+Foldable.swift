// SPDX-License-Identifier: Apache-2.0
import Foundation

public extension Result {
    /// Collapse a Result to a single value by handling both cases.
    /// fold :: (a -> b) -> (e -> b) -> Result a e -> b
    func fold<B>(onSuccess: (Success) -> B, onFailure: (Failure) -> B) -> B {
        match(caseLeft: onSuccess, caseRight: onFailure)
    }

    /// Curried fold for point-free use.
    static func fold<B: Sendable>(
        onSuccess: @escaping @Sendable (Success) -> B,
        onFailure: @escaping @Sendable (Failure) -> B
    ) -> @Sendable (Result<Success, Failure>) -> B {
        { $0.fold(onSuccess: onSuccess, onFailure: onFailure) }
    }

    /// Map the Success value to a Monoid, returning identity for Failure.
    /// foldMap :: Monoid m => (a -> m) -> Result a e -> m
    func foldMap<M: Monoid>(_ f: (Success) -> M) -> M {
        match(caseLeft: f, caseRight: const(M.identity))
    }

    /// Curried foldMap for point-free use.
    static func foldMap<M: Monoid>(
        _ f: @escaping @Sendable (Success) -> M
    ) -> (Result<Success, Failure>) -> M {
        { $0.foldMap(f) }
    }

    /// Extract the Success value as a single-element list, or empty list for Failure.
    /// toList :: Result a e -> [a]
    var toList: [Success] {
        match(caseLeft: { [$0] }, caseRight: const([]))
    }
}
