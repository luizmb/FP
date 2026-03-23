import CoreFP

public extension Either {
    /// Map the Right (B) value to a Monoid, returning identity for Left.
    /// foldMap :: Monoid m => (b -> m) -> Either a b -> m
    func foldMap<M: Monoid>(_ f: (B) -> M) -> M {
        match(caseLeft: const(M.identity), caseRight: f)
    }

    /// Curried foldMap for point-free use.
    static func foldMap<M: Monoid>(
        _ f: @escaping (B) -> M
    ) -> (Either<A, B>) -> M {
        { $0.foldMap(f) }
    }

    /// Extract the Right (B) value as a single-element list, or empty list for Left.
    /// toList :: Either a b -> [b]
    var toList: [B] {
        match(caseLeft: const([]), caseRight: { [$0] })
    }
}
