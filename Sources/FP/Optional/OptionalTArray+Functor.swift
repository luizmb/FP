import Foundation

// OptionalTArray: outer = Optional, inner = Array
// Type: [A]? = Optional<[A]>

public extension Optional {
    /// mapT for Optional<[A]> — maps over the inner Array
    /// fmap :: (a -> b) -> [a]? -> [b]?
    func mapT<A, B>(_ fn: @escaping (A) -> B) -> [B]? where Wrapped == [A] {
        map { arr in arr.map(fn) }
    }

    /// Curried fmapT for Optional<[A]>
    static func fmapT<A, B>(_ fn: @escaping (A) -> B) -> ([A]?) -> [B]? {
        { opt in opt.mapT(fn) }
    }
}
