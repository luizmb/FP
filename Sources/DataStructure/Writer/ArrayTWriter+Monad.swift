import Foundation
import CoreFP

// ArrayTWriter: outer = Array, inner = Writer
// Type: [Writer<W, A>]

public extension Array {
    /// flatMapT :: [Writer<w, a>] -> (a -> Writer<w, b>) -> [Writer<w, b>]
    func flatMapT<W: Monoid, A, B>(_ fn: (A) -> Writer<W, B>) -> [Writer<W, B>]
    where Element == Writer<W, A> {
        map { writer in writer.flatMap(fn) }
    }

    static func bindT<W: Monoid, A, B>(_ fn: @escaping (A) -> Writer<W, B>) -> ([Writer<W, A>]) -> [Writer<W, B>] {
        { arr in arr.flatMapT(fn) }
    }
}
