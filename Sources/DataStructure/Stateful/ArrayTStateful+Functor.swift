import Foundation

// ArrayTStateful: outer = Array, inner = Stateful
// Type: [Stateful<S, A>] = Array<Stateful<S, A>>

public extension Array {
    func mapT<S, A, B>(_ fn: @escaping @Sendable (A) -> B) -> [Stateful<S, B>]
    where Element == Stateful<S, A> {
        map { stateful in stateful.map(fn) }
    }

    static func fmapT<S, A, B>(_ fn: @escaping @Sendable (A) -> B) -> @Sendable ([Stateful<S, A>]) -> [Stateful<S, B>] {
        { arr in arr.mapT(fn) }
    }
}
