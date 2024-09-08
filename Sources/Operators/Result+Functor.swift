import FP

// (<$>) :: Functor f => (a -> b) -> f a -> f b
public func <£> <A1, A, B>(_ transform: @escaping (A) -> A1, _ result: Result<A, B>) -> Result<A1, B> 
where B: Sendable, A1: Sendable, A: Sendable {
    Result<A, B>.fmap(transform)(result)
}

// ($>) :: Either a b -> a0 -> Either a a0
public func £> <A1, A, B>(_ result: Result<A, B>, _ value: A1) -> Result<A1, B> {
    result.match(caseLeft: const(.left(value)), caseRight: Result.right)
}

// (<$) :: a0 -> Either a b -> Either a a0
public func <£ <A1, A, B>(_ value: A1, _ result: Result<A, B>) -> Result<A1, B> {
    result £> value
}
