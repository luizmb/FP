import Foundation
import FP

public extension Stateful {
    // StatefulT + Optional — Stateful<S, A?>

    func flatMapT<Inner, B>(
        _ fn: @escaping (Inner) -> Stateful<S, B?>
    ) -> Stateful<S, B?> where A == Inner? {
        Stateful<S, B?> { s in
            self.run(&s).flatMap { a in fn(a).run(&s) }
        }
    }

    static func bindT<Inner, B>(
        _ fn: @escaping (Inner) -> Stateful<S, B?>
    ) -> (Stateful<S, Inner?>) -> Stateful<S, B?> where A == Inner? {
        { $0.flatMapT(fn) }
    }
}
