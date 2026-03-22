import Foundation
import Core

// ResultTWriter: outer = Result, inner = Writer
// Type: Result<Writer<W, A>, E>

public extension Result {
    func mapT<W: Monoid, A, B>(_ fn: (A) -> B) -> Result<Writer<W, B>, Failure>
    where Success == Writer<W, A> {
        map { writer in writer.fmap(fn) }
    }

    static func fmapT<W: Monoid, A, B>(
        _ fn: @escaping (A) -> B
    ) -> (Result<Writer<W, A>, Failure>) -> Result<Writer<W, B>, Failure> {
        { result in result.mapT(fn) }
    }
}
