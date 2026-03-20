import Foundation
import FP

// ArrayTEither: outer = Array, inner = Either
// Type: [Either<L,A>] = Array<Either<L,A>>

public extension Array {
    /// mapT for [Either<L,A>] — maps over the inner Either's right side
    func mapT<L, A, B>(_ fn: @escaping (A) -> B) -> [Either<L, B>] where Element == Either<L, A> {
        map { either in either.mapRight(fn) }
    }

    static func fmapT<L, A, B>(_ fn: @escaping (A) -> B) -> ([Either<L, A>]) -> [Either<L, B>] {
        { arr in arr.mapT(fn) }
    }
}
