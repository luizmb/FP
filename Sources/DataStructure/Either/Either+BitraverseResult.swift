import CoreFP

public extension Either {
    // bitraverse :: (a -> Result<c,err>) -> (b -> Result<d,err>) -> Either a b -> Result<Either c d, err>
    // bitraverse lf _  (Left a)  = fmap Left  (lf a)
    // bitraverse _  rf (Right b) = fmap Right (rf b)
    func bitraverse<C, D, Err: Error>(
        _ lf: (A) -> Result<C, Err>,
        _ rf: (B) -> Result<D, Err>
    ) -> Result<Either<C, D>, Err> {
        match(
            caseLeft: { lf($0).map(Either<C, D>.left) },
            caseRight: { rf($0).map(Either<C, D>.right) }
        )
    }

    // bisequence :: Either Result<c,err> Result<d,err> -> Result<Either c d, err>
    func bisequence<C, D, Err: Error>() -> Result<Either<C, D>, Err>
        where A == Result<C, Err>, B == Result<D, Err> {
        bitraverse(CoreFP.id, CoreFP.id)
    }
}

/// bitraverse :: (a -> Result<c,err>) -> (b -> Result<d,err>) -> Either a b -> Result<Either c d, err>
public func bitraverse<A, B, C, D, Err: Error>(
    _ lf: @escaping @Sendable (A) -> Result<C, Err>,
    _ rf: @escaping @Sendable (B) -> Result<D, Err>
) -> (Either<A, B>) -> Result<Either<C, D>, Err> {
    { $0.bitraverse(lf, rf) }
}

/// bisequence :: Either Result<c,err> Result<d,err> -> Result<Either c d, err>
public func bisequence<C, D, Err: Error>(
    _ either: Either<Result<C, Err>, Result<D, Err>>
) -> Result<Either<C, D>, Err> {
    either.bisequence()
}
