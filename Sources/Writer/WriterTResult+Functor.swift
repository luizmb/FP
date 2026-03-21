import Foundation
import FP

public extension Writer {
    // WriterT + Result — Writer<W, Result<A, E>>

    func mapT<Inner, B, E: Error>(_ fn: (Inner) -> B) -> Writer<W, Result<B, E>>
    where A == Result<Inner, E> {
        mapWriter { $0.map(fn) }
    }

    static func fmapT<Inner, B, E: Error>(
        _ fn: @escaping (Inner) -> B
    ) -> (Writer<W, Result<Inner, E>>) -> Writer<W, Result<B, E>>
    where A == Result<Inner, E> {
        { $0.mapT(fn) }
    }
}
