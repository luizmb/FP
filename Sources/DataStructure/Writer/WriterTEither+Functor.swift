import CoreFP
import Foundation

public extension Writer {
    // WriterT + Either — Writer<W, Either<L, A>>

    func mapT<L, Inner, B>(_ fn: @escaping (Inner) -> B) -> Writer<W, Either<L, B>>
    where A == Either<L, Inner> {
        mapWriter(Either<L, Inner>.fmap(fn))
    }

    static func fmapT<L, Inner, B>(
        _ fn: @escaping (Inner) -> B
    ) -> (Writer<W, Either<L, Inner>>) -> Writer<W, Either<L, B>>
    where A == Either<L, Inner> {
        { $0.mapT(fn) }
    }
}
