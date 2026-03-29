import Foundation
import CoreFP

public extension Stateful {
    func flatMap<B>(_ fn: @escaping (A) -> Stateful<S, B>) -> Stateful<S, B> {
        Stateful<S, B> { s in
            let a = self.run(&s)
            return fn(a).run(&s)
        }
    }

    static func bind<B>(
        _ fn: @escaping (A) -> Stateful<S, B>
    ) -> (Stateful<S, A>) -> Stateful<S, B> {
        { $0.flatMap(fn) }
    }

    static func kleisli<O0, B>(
        _ fn1: @escaping (O0) -> Stateful<S, A>,
        _ fn2: @escaping (A) -> Stateful<S, B>
    ) -> (O0) -> Stateful<S, B> {
        { o0 in fn1(o0).flatMap(fn2) }
    }

    static func kleisliBack<O0, B>(
        _ fn2: @escaping (A) -> Stateful<S, B>,
        _ fn1: @escaping (O0) -> Stateful<S, A>
    ) -> (O0) -> Stateful<S, B> {
        { o0 in fn1(o0).flatMap(fn2) }
    }

    static func join<O>(
        _ nested: Stateful<S, Stateful<S, O>>
    ) -> Stateful<S, O> where A == Stateful<S, O> {
        nested.flatMap(CoreFP.id)
    }

    func void() -> Stateful<S, Void> {
        fmap(ignore)
    }
}
