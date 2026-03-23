import CoreFP

public extension Either {
    // traverse :: (b -> c?) -> Either a b -> Either a c?
    // traverse _ (Left a)  = Just (Left a)
    // traverse f (Right b) = fmap Right (f b)
    func traverse<C>(_ f: (B) -> C?) -> Either<A, C>? {
        match(
            caseLeft: { .some(.left($0)) },
            caseRight: { f($0).map(Either<A, C>.right) }
        )
    }

    // sequence :: Either a c? -> Either a c?
    // sequence = traverse id
    func sequence<C>() -> Either<A, C>? where B == C? {
        traverse(CoreFP.id)
    }
}
