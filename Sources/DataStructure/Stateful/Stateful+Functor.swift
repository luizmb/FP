import Foundation

public extension Stateful {
    func mapStateful<B>(_ fn: @escaping (A) -> B) -> Stateful<S, B> {
        Stateful<S, B> { s in fn(self.run(&s)) }
    }

    func fmap<B>(_ fn: @escaping (A) -> B) -> Stateful<S, B> {
        mapStateful(fn)
    }

    static func fmap<B>(
        _ fn: @escaping (A) -> B
    ) -> (Stateful<S, A>) -> Stateful<S, B> {
        { $0.mapStateful(fn) }
    }
}
