import Foundation
import FP

public extension Stateful {
    // StatefulT + Optional — Stateful<S, A?>

    func mapT<Inner, B>(_ fn: @escaping (Inner) -> B) -> Stateful<S, B?> where A == Inner? {
        mapStateful(Optional<Inner>.fmap(fn))
    }

    static func fmapT<Inner, B>(
        _ fn: @escaping (Inner) -> B
    ) -> (Stateful<S, Inner?>) -> Stateful<S, B?> where A == Inner? {
        { $0.mapT(fn) }
    }
}
