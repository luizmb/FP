import Foundation
import Core

// StatefulTWriter: outer = Stateful, inner = Writer
// Type: Stateful<S, Writer<W, A>>
//
// flatMapT works: Stateful's flatMap threads `inout S` through both steps,
// and Writer's flatMap accumulates the log eagerly once the state is applied.

public extension Stateful {
    /// flatMapT :: Stateful<s, Writer<w, a>> -> (a -> Writer<w, b>) -> Stateful<s, Writer<w, b>>
    func flatMapT<W: Monoid, Inner, B>(_ fn: @escaping (Inner) -> Writer<W, B>) -> Stateful<S, Writer<W, B>>
    where A == Writer<W, Inner> {
        mapStateful { writer in writer.flatMap(fn) }
    }

    static func bindT<W: Monoid, Inner, B>(
        _ fn: @escaping (Inner) -> Writer<W, B>
    ) -> (Stateful<S, Writer<W, Inner>>) -> Stateful<S, Writer<W, B>>
    where A == Writer<W, Inner> {
        { $0.flatMapT(fn) }
    }
}
