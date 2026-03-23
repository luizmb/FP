import CoreFP

public extension Validation {
    // bitraverse :: (e -> [e1]) -> (a -> [b]) -> Validation e a -> [Validation e1 b]
    // bitraverse ef _  (Failure e) = fmap Failure (ef e)
    // bitraverse _  af (Success a) = fmap Success (af a)
    func bitraverse<E1: Semigroup, B>(_ ef: (E) -> [E1], _ af: (A) -> [B]) -> [Validation<E1, B>] {
        match(
            caseFailure: { ef($0).map(Validation<E1, B>.failure) },
            caseSuccess: { af($0).map(Validation<E1, B>.success) }
        )
    }

    // bisequence :: Validation [e1] [b] -> [Validation e1 b]
    func bisequence<E1: Semigroup, B>() -> [Validation<E1, B>] where E == [E1], A == [B] {
        bitraverse(CoreFP.id, CoreFP.id)
    }
}

/// bitraverse :: (e -> [e1]) -> (a -> [b]) -> Validation e a -> [Validation e1 b]
public func bitraverse<E: Semigroup, A, E1: Semigroup, B>(
    _ ef: @escaping (E) -> [E1],
    _ af: @escaping (A) -> [B]
) -> (Validation<E, A>) -> [Validation<E1, B>] {
    { $0.bitraverse(ef, af) }
}

/// bisequence :: Validation [e1] [b] -> [Validation e1 b]
public func bisequence<E1: Semigroup, B>(_ v: Validation<[E1], [B]>) -> [Validation<E1, B>] {
    v.bisequence()
}
