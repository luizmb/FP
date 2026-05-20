import Foundation

// ArrayTOptional: outer = Array, inner = Optional
// Type: [A?] = Array<Optional<A>>

public extension Array {
    /// mapT for [A?] — maps over the inner Optional
    /// fmap :: (a -> b) -> [a?] -> [b?]
    func mapT<A, B>(_ fn: @escaping @Sendable (A) -> B) -> [B?] where Element == A? {
        map { optA in optA.map(fn) }
    }

    /// Curried fmapT for [A?]
    static func fmapT<A, B>(_ fn: @escaping @Sendable (A) -> B) -> @Sendable ([A?]) -> [B?] {
        { arr in arr.mapT(fn) }
    }
}
