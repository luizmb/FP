import CoreFP

public extension Either {
    // traverse :: (b -> Result<c, e>) -> Either a b -> Result<Either a c, e>
    // traverse _ (Left a)  = .success(.left(a))
    // traverse f (Right b) = fmap Right (f b)
    func traverse<C, E: Error>(_ f: (B) -> Result<C, E>) -> Result<Either<A, C>, E> {
        match(
            caseLeft: { .success(.left($0)) },
            caseRight: { f($0).map(Either<A, C>.right) }
        )
    }

    // sequence :: Either a (Result<c, e>) -> Result<Either a c, e>
    // sequence = traverse id
    func sequence<C, E: Error>() -> Result<Either<A, C>, E> where B == Result<C, E> {
        traverse(CoreFP.id)
    }
}
