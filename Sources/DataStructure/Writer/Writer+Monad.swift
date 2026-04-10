import CoreFP
import Foundation

public extension Writer {
    /// flatMap :: Writer<w, a> -> (a -> Writer<w, b>) -> Writer<w, b>
    /// Sequences computations, combining logs with Monoid.combine.
    func flatMap<B>(_ fn: (A) -> Writer<W, B>) -> Writer<W, B> {
        let wb = fn(value)
        return Writer<W, B>(wb.value, W.combine(log, wb.log))
    }

    static func bind<B>(
        _ fn: @escaping (A) -> Writer<W, B>
    ) -> (Writer<W, A>) -> Writer<W, B> {
        { $0.flatMap(fn) }
    }

    static func kleisli<O0, B>(
        _ fn1: @escaping (O0) -> Writer<W, A>,
        _ fn2: @escaping (A) -> Writer<W, B>
    ) -> (O0) -> Writer<W, B> {
        { o0 in fn1(o0).flatMap(fn2) }
    }

    static func kleisliBack<O0, B>(
        _ fn2: @escaping (A) -> Writer<W, B>,
        _ fn1: @escaping (O0) -> Writer<W, A>
    ) -> (O0) -> Writer<W, B> {
        { o0 in fn1(o0).flatMap(fn2) }
    }

    static func join<O>(
        _ nested: Writer<W, Writer<W, O>>
    ) -> Writer<W, O> where A == Writer<W, O> {
        nested.flatMap(CoreFP.id)
    }

    func void() -> Writer<W, Void> {
        map(ignore)
    }
}
