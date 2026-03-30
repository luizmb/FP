import CoreFP
import Foundation

public extension Stateful {
    // StatefulT + Array — Stateful<S, [A]>

    func mapT<Inner, B>(_ fn: @escaping (Inner) -> B) -> Stateful<S, [B]> where A == [Inner] {
        mapStateful([Inner].fmap(fn))
    }

    static func fmapT<Inner, B>(
        _ fn: @escaping (Inner) -> B
    ) -> (Stateful<S, [Inner]>) -> Stateful<S, [B]> where A == [Inner] {
        { $0.mapT(fn) }
    }
}
