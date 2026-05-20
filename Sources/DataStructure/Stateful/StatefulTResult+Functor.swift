import CoreFP
import Foundation

public extension Stateful {
    // StatefulT + Result — Stateful<S, Result<A, E>>

    func mapT<Inner, B, E: Error>(_ fn: @escaping @Sendable (Inner) -> B) -> Stateful<S, Result<B, E>>
    where A == Result<Inner, E> {
        mapStateful(Result<Inner, E>.fmap(fn))
    }

    static func fmapT<Inner, B, E: Error>(
        _ fn: @escaping @Sendable (Inner) -> B
    ) -> @Sendable (Stateful<S, Result<Inner, E>>) -> Stateful<S, Result<B, E>>
    where A == Result<Inner, E> {
        { $0.mapT(fn) }
    }
}
