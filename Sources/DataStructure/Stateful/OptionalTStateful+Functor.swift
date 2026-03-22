import Foundation
import Core

// OptionalTStateful: outer = Optional, inner = Stateful
// Type: Stateful<S, A>? = Optional<Stateful<S, A>>

public extension Optional {
    func mapT<S, A, B>(_ fn: @escaping (A) -> B) -> Stateful<S, B>?
    where Wrapped == Stateful<S, A> {
        map { stateful in stateful.fmap(fn) }
    }

    static func fmapT<S, A, B>(_ fn: @escaping (A) -> B) -> (Stateful<S, A>?) -> Stateful<S, B>? {
        { opt in opt.mapT(fn) }
    }
}
