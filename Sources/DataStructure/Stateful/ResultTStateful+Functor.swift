import Foundation
import Core

// ResultTStateful: outer = Result, inner = Stateful
// Type: Result<Stateful<S, A>, E> = Result wrapping a Stateful computation

public extension Result {
    func mapT<S, A, B>(_ fn: @escaping (A) -> B) -> Result<Stateful<S, B>, Failure>
    where Success == Stateful<S, A> {
        map { stateful in stateful.fmap(fn) }
    }

    static func fmapT<S, A, B>(_ fn: @escaping (A) -> B) -> (Result<Stateful<S, A>, Failure>) -> Result<Stateful<S, B>, Failure> {
        { result in result.mapT(fn) }
    }
}
