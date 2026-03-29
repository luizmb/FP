import CoreFP

public extension Validation {
    // bitraverse :: (e -> Result<e1,err>) -> (a -> Result<b,err>) -> Validation e a -> Result<Validation e1 b, err>
    // bitraverse ef _  (Failure e) = fmap Failure (ef e)
    // bitraverse _  af (Success a) = fmap Success (af a)
    func bitraverse<E1: Semigroup, B, Err: Error>(
        _ ef: (E) -> Result<E1, Err>,
        _ af: (A) -> Result<B, Err>
    ) -> Result<Validation<E1, B>, Err> {
        match(
            caseFailure: { ef($0).map(Validation<E1, B>.failure) },
            caseSuccess: { af($0).map(Validation<E1, B>.success) }
        )
    }
}

/// bitraverse :: (e -> Result<e1,err>) -> (a -> Result<b,err>) -> Validation e a -> Result<Validation e1 b, err>
public func bitraverse<E: Semigroup, A, E1: Semigroup, B, Err: Error>(
    _ ef: @escaping (E) -> Result<E1, Err>,
    _ af: @escaping (A) -> Result<B, Err>
) -> (Validation<E, A>) -> Result<Validation<E1, B>, Err> {
    { $0.bitraverse(ef, af) }
}
