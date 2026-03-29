import CoreFP
import Foundation

// ReaderTStateful: outer = Reader, inner = Stateful
// Type: Reader<Env, Stateful<S, A>>

public extension Reader {
    func mapT<S, A, B>(_ fn: @escaping (A) -> B) -> Reader<Environment, Stateful<S, B>>
    where Output == Stateful<S, A> {
        mapReader { stateful in stateful.fmap(fn) }
    }

    static func fmapT<S, A, B>(
        _ fn: @escaping (A) -> B
    ) -> (Reader<Environment, Stateful<S, A>>) -> Reader<Environment, Stateful<S, B>>
    where Output == Stateful<S, A> {
        { $0.mapT(fn) }
    }
}
