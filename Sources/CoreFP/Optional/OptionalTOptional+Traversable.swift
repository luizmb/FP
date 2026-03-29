public extension Optional {
    // traverse :: (a -> b?) -> a? -> b??
    // traverse _ Nothing  = Just Nothing
    // traverse f (Just a) = fmap Just (f a)
    func traverse<B>(_ f: (Wrapped) -> B?) -> B?? {
        switch self {
        case .none:
            .some(.none)
        case .some(let a):
            f(a).map(B?.some)
        }
    }

    // sequence :: a?? -> a??
    // sequence = traverse id
    func sequence<A>() -> A?? where Wrapped == A? {
        traverse(CoreFP.id)
    }
}
