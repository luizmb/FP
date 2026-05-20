import Foundation

// ArrayTOptional: outer = Array, inner = Optional
// Type: [A?] = Array<Optional<A>>
// Haskell: MaybeT []

public extension Array {
    /// flatMapT for [A?]
    /// (>>=) :: [a?] -> (a -> [b?]) -> [b?]
    /// For each element: nil → [nil], .some(a) → fn(a)
    func flatMapT<A, B>(_ fn: @escaping @Sendable (A) -> [B?]) -> [B?] where Element == A? {
        flatMap { optA in optA.map(fn) ?? [.none] }
    }

    /// Curried bindT for [A?]
    static func bindT<A, B>(_ fn: @escaping @Sendable (A) -> [B?]) -> ([A?]) -> [B?] {
        { arr in arr.flatMapT(fn) }
    }
}
