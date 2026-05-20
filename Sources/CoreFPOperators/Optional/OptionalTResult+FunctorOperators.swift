import CoreFP

// OptionalTResult: outer = Optional, inner = Result
// Type: Result<A,E>? = Optional<Result<A,E>>

// (<£^>) :: (a -> b) -> Result<a,e>? -> Result<b,e>?
public func <£^> <A, B, E: Error>(_ fn: @escaping @Sendable (A) -> B, _ opt: Result<A, E>?) -> Result<B, E>? {
    opt.mapT(fn)
}

// (<&^>) :: Result<a,e>? -> (a -> b) -> Result<b,e>?
public func <&^> <A, B, E: Error>(_ opt: Result<A, E>?, _ fn: @escaping @Sendable (A) -> B) -> Result<B, E>? {
    opt.mapT(fn)
}
