import Foundation
import FP

// ArrayTWriter: outer = Array, inner = Writer
// Type: [Writer<W, A>]

public extension Array {
    func mapT<W: Monoid, A, B>(_ fn: (A) -> B) -> [Writer<W, B>]
    where Element == Writer<W, A> {
        map { writer in writer.fmap(fn) }
    }

    static func fmapT<W: Monoid, A, B>(_ fn: @escaping (A) -> B) -> ([Writer<W, A>]) -> [Writer<W, B>] {
        { arr in arr.mapT(fn) }
    }
}
