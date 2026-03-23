import CoreFP

public extension Validation {
    // traverse :: (a -> b?) -> Validation e a -> Validation e b?
    // traverse _ (Failure e) = Just (Failure e)
    // traverse f (Success a) = fmap Success (f a)
    func traverse<B>(_ f: (A) -> B?) -> Validation<E, B>? {
        match(
            caseFailure: { .some(.failure($0)) },
            caseSuccess: { f($0).map(Validation<E, B>.success) }
        )
    }

    // sequence :: Validation e b? -> Validation e b?
    // sequence = traverse id
    func sequence<B>() -> Validation<E, B>? where A == B? {
        traverse(CoreFP.id)
    }
}
