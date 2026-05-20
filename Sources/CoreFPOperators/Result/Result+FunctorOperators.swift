import CoreFP

// (<$>) :: Functor f => (a -> b) -> f a -> f b
public func <£> <A1, A, B>(_ transform: @escaping @Sendable (A) -> A1, _ result: Result<A, B>) -> Result<A1, B> {
    Result<A, B>.fmap(transform)(result)
}

// ($>) :: Result<A, B> -> a0 -> Result<a0, B>
public func £> <A1, A, B>(_ result: Result<A, B>, _ value: A1) -> Result<A1, B> {
    result.match(caseLeft: const(.left(value)), caseRight: Result.right)
}

// (<$) :: a0 -> Result<A, B> -> Result<a0, B>
public func <£ <A1, A, B>(_ value: A1, _ result: Result<A, B>) -> Result<A1, B> {
    result £> value
}
