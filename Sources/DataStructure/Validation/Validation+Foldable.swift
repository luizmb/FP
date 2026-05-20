import CoreFP

public extension Validation {
    /// Map the Success value to a Monoid, returning identity for Failure.
    /// foldMap :: Monoid m => (a -> m) -> Validation e a -> m
    func foldMap<M: Monoid>(_ f: (A) -> M) -> M {
        match(caseFailure: const(M.identity), caseSuccess: f)
    }

    /// Curried foldMap for point-free use.
    static func foldMap<M: Monoid>(
        _ f: @escaping @Sendable (A) -> M
    ) -> (Validation<E, A>) -> M {
        { $0.foldMap(f) }
    }

    /// Extract the Success value as a single-element list, or empty list for Failure.
    /// toList :: Validation e a -> [a]
    var toList: [A] {
        match(caseFailure: const([]), caseSuccess: { [$0] })
    }
}
