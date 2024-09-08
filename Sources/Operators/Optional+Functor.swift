import FP

// (<$>) :: Functor f => (a -> b) -> f a -> f b
public func <£> <A1, A>(_ transform: @escaping (A) -> A1, _ optional: Optional<A>) -> Optional<A1>
where A1: Sendable, A: Sendable {
    Optional<A>.fmap(transform)(optional)
}

// ($>) :: Either a b -> a0 -> Either a a0
public func £> <A1, A>(_ optional: Optional<A>, _ value: A1) -> Optional<A1> {
    optional.match(caseLeft: const(.left(value)), caseRight: Optional.right)
}

// (<$) :: a0 -> Either a b -> Either a a0
public func <£ <A1, A>(_ value: A1, _ optional: Optional<A>) -> Optional<A1> {
    optional £> value
}
