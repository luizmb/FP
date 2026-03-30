import CoreFP
import Foundation

// ReaderTWriter: outer = Reader, inner = Writer
// Type: Reader<Env, Writer<W, A>>

public extension Reader {
    func mapT<W: Monoid, A, B>(_ fn: @escaping (A) -> B) -> Reader<Environment, Writer<W, B>>
    where Output == Writer<W, A> {
        mapReader { writer in writer.fmap(fn) }
    }

    static func fmapT<W: Monoid, A, B>(
        _ fn: @escaping (A) -> B
    ) -> (Reader<Environment, Writer<W, A>>) -> Reader<Environment, Writer<W, B>>
    where Output == Writer<W, A> {
        { $0.mapT(fn) }
    }
}
