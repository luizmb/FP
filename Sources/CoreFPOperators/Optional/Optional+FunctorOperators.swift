import CoreFP

// (<$>) :: Functor f => (a -> b) -> f a -> f b
public func <£> <A1, A>(_ transform: @escaping (A) -> A1, _ optional: Optional<A>) -> Optional<A1> {
    Optional<A>.fmap(transform)(optional)
}

// ($>) :: Optional<A> -> b -> Optional<b>
public func £> <A1, A>(_ optional: Optional<A>, _ value: A1) -> Optional<A1> {
    optional.match(caseLeft: const(.left(value)), caseRight: Optional.right)
}

// (<$) :: b -> Optional<A> -> Optional<b>
public func <£ <A1, A>(_ value: A1, _ optional: Optional<A>) -> Optional<A1> {
    optional £> value
}
