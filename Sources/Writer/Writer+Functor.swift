import Foundation
import FP

public extension Writer {
    func mapWriter<B>(_ fn: (A) -> B) -> Writer<W, B> {
        Writer<W, B>(fn(value), log)
    }

    func fmap<B>(_ fn: (A) -> B) -> Writer<W, B> {
        mapWriter(fn)
    }

    static func fmap<B>(
        _ fn: @escaping (A) -> B
    ) -> (Writer<W, A>) -> Writer<W, B> {
        { $0.mapWriter(fn) }
    }
}
