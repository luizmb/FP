import CoreFP

// ArrayTResult: outer = Array, inner = Result
// Type: [Result<A,E>] = Array<Result<A,E>>

// (<£^>) :: (a -> b) -> [Result<a,e>] -> [Result<b,e>]
public func <£^> <A, B, E: Error>(_ fn: @escaping (A) -> B, _ arr: [Result<A, E>]) -> [Result<B, E>] {
    arr.mapT(fn)
}

// (<&^>) :: [Result<a,e>] -> (a -> b) -> [Result<b,e>]
public func <&^> <A, B, E: Error>(_ arr: [Result<A, E>], _ fn: @escaping (A) -> B) -> [Result<B, E>] {
    arr.mapT(fn)
}
