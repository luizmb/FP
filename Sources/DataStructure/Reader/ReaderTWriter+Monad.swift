import CoreFP
import Foundation

// ReaderTWriter: outer = Reader, inner = Writer
// Type: Reader<Env, Writer<W, A>>
//
// flatMapT works: Reader's flatMap composes functions, and Writer's flatMap
// accumulates the log eagerly once the environment is applied.

public extension Reader {
    /// flatMapT :: Reader<env, Writer<w, a>> -> (a -> Writer<w, b>) -> Reader<env, Writer<w, b>>
    func flatMapT<W: Monoid, A, B>(_ fn: @escaping (A) -> Writer<W, B>) -> Reader<Environment, Writer<W, B>>
    where Output == Writer<W, A> {
        mapReader { writer in writer.flatMap(fn) }
    }

    static func bindT<W: Monoid, A, B>(
        _ fn: @escaping (A) -> Writer<W, B>
    ) -> (Reader<Environment, Writer<W, A>>) -> Reader<Environment, Writer<W, B>>
    where Output == Writer<W, A> {
        { $0.flatMapT(fn) }
    }
}
