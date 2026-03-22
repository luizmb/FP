import Foundation
import CoreFP

// ArrayTStateful: outer = Array, inner = Stateful
// Type: [Stateful<S, A>] = Array<Stateful<S, A>>

public extension Array {
    func mapT<S, A, B>(_ fn: @escaping (A) -> B) -> [Stateful<S, B>]
    where Element == Stateful<S, A> {
        map { stateful in stateful.fmap(fn) }
    }

    static func fmapT<S, A, B>(_ fn: @escaping (A) -> B) -> ([Stateful<S, A>]) -> [Stateful<S, B>] {
        { arr in arr.mapT(fn) }
    }
}
