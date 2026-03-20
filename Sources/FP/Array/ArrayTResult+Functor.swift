import Foundation

// ArrayTResult: outer = Array, inner = Result
// Type: [Result<A,E>] = Array<Result<A,E>>

public extension Array {
    /// mapT for [Result<A,E>] — maps over the inner Result's Success
    /// fmap :: (a -> b) -> [Result<a,e>] -> [Result<b,e>]
    func mapT<A, B, E: Error>(_ fn: @escaping (A) -> B) -> [Result<B, E>] where Element == Result<A, E> {
        map { result in result.map(fn) }
    }

    /// Curried fmapT for [Result<A,E>]
    static func fmapT<A, B, E: Error>(_ fn: @escaping (A) -> B) -> ([Result<A, E>]) -> [Result<B, E>] {
        { arr in arr.mapT(fn) }
    }
}
