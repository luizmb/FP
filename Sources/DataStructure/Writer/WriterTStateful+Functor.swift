import Foundation

public extension Writer {
    // WriterT + Stateful — Writer<W, Stateful<S, A>>

    func mapT<S, Inner, B>(_ fn: @escaping @Sendable (Inner) -> B) -> Writer<W, Stateful<S, B>>
    where A == Stateful<S, Inner> {
        mapWriter(Stateful<S, Inner>.fmap(fn))
    }

    static func fmapT<S, Inner, B>(
        _ fn: @escaping @Sendable (Inner) -> B
    ) -> @Sendable (Writer<W, Stateful<S, Inner>>) -> Writer<W, Stateful<S, B>>
    where A == Stateful<S, Inner> {
        { $0.mapT(fn) }
    }
}
