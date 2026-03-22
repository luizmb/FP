import CoreFP

// OptionalTResult: outer = Optional, inner = Result
// Type: Result<A,E>? = Optional<Result<A,E>>

// (<*>) :: Result<(a -> b), e>? -> Result<a, e>? -> Result<b, e>?
public func <*> <A, B, E: Error>(_ fns: Result<(A) -> B, E>?, _ values: Result<A, E>?) -> Result<B, E>? {
    applyOptionalResult(fns, values)
}

// (*>) :: Result<a,e>? -> Result<b,e>? -> Result<b,e>?
public func *> <A, B, E: Error>(_ lhs: Result<A, E>?, _ rhs: Result<B, E>?) -> Result<B, E>? {
    seqRightOptionalResult(lhs, rhs)
}

// (<*) :: Result<a,e>? -> Result<b,e>? -> Result<a,e>?
public func <* <A, B, E: Error>(_ lhs: Result<A, E>?, _ rhs: Result<B, E>?) -> Result<A, E>? {
    seqLeftOptionalResult(lhs, rhs)
}
