import Foundation
import Core

public extension Writer {
    // WriterT + Reader — Writer<W, Reader<Env, A>>

    func mapT<Env, Inner, B>(_ fn: @escaping (Inner) -> B) -> Writer<W, Reader<Env, B>>
    where A == Reader<Env, Inner> {
        mapWriter(Reader<Env, Inner>.fmap(fn))
    }

    static func fmapT<Env, Inner, B>(
        _ fn: @escaping (Inner) -> B
    ) -> (Writer<W, Reader<Env, Inner>>) -> Writer<W, Reader<Env, B>>
    where A == Reader<Env, Inner> {
        { $0.mapT(fn) }
    }
}
