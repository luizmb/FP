import Foundation
import CoreFP

public extension Stateful {
    // StatefulT + Reader — Stateful<S, Reader<Env, A>>

    func mapT<Env, Inner, B>(_ fn: @escaping (Inner) -> B) -> Stateful<S, Reader<Env, B>>
    where A == Reader<Env, Inner> {
        mapStateful(Reader<Env, Inner>.fmap(fn))
    }

    static func fmapT<Env, Inner, B>(
        _ fn: @escaping (Inner) -> B
    ) -> (Stateful<S, Reader<Env, Inner>>) -> Stateful<S, Reader<Env, B>>
    where A == Reader<Env, Inner> {
        { $0.mapT(fn) }
    }
}
