import CoreFP

// (<$>) :: Functor f => (a -> b) -> f a -> f b
public func <£> <A1, A>(_ transform: @escaping @Sendable (A) -> A1, _ optional: A?) -> A1? {A?.fmap(transform)(optional)
}

// ($>) :: Optional<A> -> b -> Optional<b>
public func £> <A1, A>(_ optional: A?, _ value: A1) -> A1? {
    optional.match(caseLeft: const(.left(value)), caseRight: Optional.right)
}

// (<$) :: b -> Optional<A> -> Optional<b>
public func <£ <A1, A>(_ value: A1, _ optional: A?) -> A1? {
    optional £> value
}
