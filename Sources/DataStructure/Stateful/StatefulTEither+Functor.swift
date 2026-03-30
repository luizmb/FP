import Foundation

public extension Stateful {
    // StatefulT + Either — Stateful<S, Either<L, A>>

    func mapT<L, Inner, B>(_ fn: @escaping (Inner) -> B) -> Stateful<S, Either<L, B>>
    where A == Either<L, Inner>, Inner: Sendable, L: Sendable {
        mapStateful(Either<L, Inner>.fmap(fn))
    }

    static func fmapT<L, Inner, B>(
        _ fn: @escaping (Inner) -> B
    ) -> (Stateful<S, Either<L, Inner>>) -> Stateful<S, Either<L, B>>
    where Inner: Sendable, L: Sendable, A == Either<L, Inner> {
        { $0.mapT(fn) }
    }
}
