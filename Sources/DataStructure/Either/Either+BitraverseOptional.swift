import CoreFP

public extension Either {
    // bitraverse :: (a -> c?) -> (b -> d?) -> Either a b -> Either c d?
    // bitraverse lf _  (Left a)  = fmap Left  (lf a)
    // bitraverse _  rf (Right b) = fmap Right (rf b)
    func bitraverse<C, D>(_ lf: (A) -> C?, _ rf: (B) -> D?) -> Either<C, D>? {
        match(
            caseLeft:  { lf($0).map(Either<C, D>.left) },
            caseRight: { rf($0).map(Either<C, D>.right) }
        )
    }

    // bisequence :: Either c? d? -> Either c d?
    func bisequence<C, D>() -> Either<C, D>? where A == C?, B == D? {
        bitraverse(CoreFP.id, CoreFP.id)
    }
}

/// bitraverse :: (a -> c?) -> (b -> d?) -> Either a b -> Either c d?
public func bitraverse<A, B, C, D>(
    _ lf: @escaping (A) -> C?,
    _ rf: @escaping (B) -> D?
) -> (Either<A, B>) -> Either<C, D>? {
    { $0.bitraverse(lf, rf) }
}

/// bisequence :: Either c? d? -> Either c d?
public func bisequence<C, D>(_ either: Either<C?, D?>) -> Either<C, D>? {
    either.bisequence()
}
