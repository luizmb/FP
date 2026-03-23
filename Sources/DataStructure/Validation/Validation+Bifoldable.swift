import CoreFP

public extension Validation {
    /// bifoldMap :: (e -> c) -> (a -> c) -> Validation e a -> c
    /// Eliminate a Validation by folding both sides to a common type.
    func bifoldMap<C>(_ ef: (E) -> C, _ af: (A) -> C) -> C {
        match(caseFailure: ef, caseSuccess: af)
    }

    /// Curried static form for point-free use.
    static func bifoldMap<C>(
        _ ef: @escaping (E) -> C,
        _ af: @escaping (A) -> C
    ) -> (Validation<E, A>) -> C {
        { $0.bifoldMap(ef, af) }
    }
}

/// bifoldMap :: (e -> c) -> (a -> c) -> Validation e a -> c
public func bifoldMap<E: Semigroup, A, C>(
    _ ef: @escaping (E) -> C,
    _ af: @escaping (A) -> C
) -> (Validation<E, A>) -> C {
    { $0.bifoldMap(ef, af) }
}
