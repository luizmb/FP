import Foundation
import Core

// ArrayTEither: outer = Array, inner = Either
// Type: [Either<L,A>] = Array<Either<L,A>>
// Haskell: ExceptT l []

public extension Array {
    /// flatMapT for [Either<L,A>]
    /// .left(l)  → [.left(l)]
    /// .right(a) → fn(a)
    func flatMapT<L, A, B>(_ fn: @escaping (A) -> [Either<L, B>]) -> [Either<L, B>]
    where Element == Either<L, A> {
        flatMap { either in
            either.match(
                caseLeft: { l in [.left(l)] },
                caseRight: { a in fn(a) }
            )
        }
    }

    static func bindT<L, A, B>(
        _ fn: @escaping (A) -> [Either<L, B>]
    ) -> ([Either<L, A>]) -> [Either<L, B>] {
        { arr in arr.flatMapT(fn) }
    }
}
