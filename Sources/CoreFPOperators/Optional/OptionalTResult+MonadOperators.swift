import CoreFP

// OptionalTResult: outer = Optional, inner = Result
// Type: Result<A,E>? = Optional<Result<A,E>>

// (>>-) :: Result<a,e>? -> (a -> Result<b,e>?) -> Result<b,e>?
public func >>- <A, B, E: Error>(_ opt: Result<A, E>?, _ fn: @escaping @Sendable (A) -> Result<B, E>?) -> Result<B, E>? {
    opt.flatMapT(fn)
}

// (-<<) :: (a -> Result<b,e>?) -> Result<a,e>? -> Result<b,e>?
public func -<< <A, B, E: Error>(_ fn: @escaping @Sendable (A) -> Result<B, E>?, _ opt: Result<A, E>?) -> Result<B, E>? {
    opt.flatMapT(fn)
}

// (>=>) :: (a -> Result<b,e>?) -> (b -> Result<c,e>?) -> a -> Result<c,e>?
public func >=> <A, B, C, E: Error>(
    _ fn1: @escaping @Sendable (A) -> Result<B, E>?,
    _ fn2: @escaping @Sendable (B) -> Result<C, E>?
) -> (A) -> Result<C, E>? {
    { a in fn1(a).flatMapT(fn2) }
}
