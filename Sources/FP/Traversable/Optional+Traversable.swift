public extension Optional {
    // traverse :: (a -> [b]) -> a? -> [b?]
    // traverse _ Nothing  = [Nothing]
    // traverse f (Just a) = fmap Just (f a)
    func traverse<B>(_ f: (Wrapped) -> [B]) -> [B?] {
        switch self {
        case .none:
            [.none]
        case .some(let a):
            f(a).map(Optional<B>.some)
        }
    }

    // traverse :: (a -> b?) -> a? -> b??
    // traverse _ Nothing  = Just Nothing
    // traverse f (Just a) = fmap Just (f a)
    func traverse<B>(_ f: (Wrapped) -> B?) -> B?? {
        switch self {
        case .none:
            .some(.none)
        case .some(let a):
            f(a).map(Optional<B>.some)
        }
    }

    // traverse :: (a -> Result<b,e>) -> a? -> Result<b?,e>
    // traverse _ Nothing  = Right Nothing
    // traverse f (Just a) = fmap Just (f a)
    func traverse<B, E: Error>(_ f: (Wrapped) -> Result<B, E>) -> Result<B?, E> {
        switch self {
        case .none:
            .success(.none)
        case .some(let a):
            f(a).map(Optional<B>.some)
        }
    }

    // sequence :: [a]? -> [a?]
    // sequence = traverse id
    func sequence<A>() -> [A?] where Wrapped == [A] {
        traverse { $0 }
    }

    // sequence :: a?? -> a??
    // sequence = traverse id
    func sequence<A>() -> A?? where Wrapped == A? {
        traverse { $0 }
    }

    // sequence :: Result<a,e>? -> Result<a?,e>
    // sequence = traverse id
    func sequence<A, E: Error>() -> Result<A?, E> where Wrapped == Result<A, E> {
        traverse { $0 }
    }
}
