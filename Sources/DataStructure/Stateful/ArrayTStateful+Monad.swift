import Foundation

// ArrayTStateful: outer = Array, inner = Stateful
// Type: [Stateful<S, A>] = Array<Stateful<S, A>>
//
// flatMapT sequences computations structurally: each Stateful<S, A> in the array
// is composed with fn via flatMap. Empty array propagates as empty array.

public extension Array {
    /// flatMapT :: [Stateful<s, a>] -> (a -> Stateful<s, b>) -> [Stateful<s, b>]
    func flatMapT<S, A, B>(_ fn: @escaping @Sendable (A) -> Stateful<S, B>) -> [Stateful<S, B>]
    where Element == Stateful<S, A> {
        map { stateful in stateful.flatMap(fn) }
    }

    static func bindT<S, A, B>(_ fn: @escaping @Sendable (A) -> Stateful<S, B>) -> ([Stateful<S, A>]) -> [Stateful<S, B>] {
        { arr in arr.flatMapT(fn) }
    }
}
