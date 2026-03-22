import Foundation
import CoreFP

// ReaderTStateful: outer = Reader, inner = Stateful
// Type: Reader<Env, Stateful<S, A>>

public extension Reader {
    /// flatMapT :: Reader<env, Stateful<s, a>> -> (a -> Stateful<s, b>) -> Reader<env, Stateful<s, b>>
    func flatMapT<S, A, B>(_ fn: @escaping (A) -> Stateful<S, B>) -> Reader<Environment, Stateful<S, B>>
    where Output == Stateful<S, A> {
        mapReader { stateful in stateful.flatMap(fn) }
    }

    static func bindT<S, A, B>(
        _ fn: @escaping (A) -> Stateful<S, B>
    ) -> (Reader<Environment, Stateful<S, A>>) -> Reader<Environment, Stateful<S, B>>
    where Output == Stateful<S, A> {
        { $0.flatMapT(fn) }
    }
}
