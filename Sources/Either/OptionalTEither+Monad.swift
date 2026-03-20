import Foundation
import FP

// OptionalTEither: outer = Optional, inner = Either
// Type: Either<L,A>? = Optional<Either<L,A>>
// Haskell: ExceptT l Maybe

public extension Optional {
    /// flatMapT for Optional<Either<L,A>>
    /// nil         → nil
    /// .some(.left(l))  → .some(.left(l))
    /// .some(.right(a)) → fn(a)
    func flatMapT<L, A, B>(_ fn: @escaping (A) -> Either<L, B>?) -> Either<L, B>? where Wrapped == Either<L, A> {
        flatMap { either in
            either.match(
                caseLeft: { l in .some(.left(l)) },
                caseRight: { a in fn(a) }
            )
        }
    }

    static func bindT<L, A, B>(_ fn: @escaping (A) -> Either<L, B>?) -> (Either<L, A>?) -> Either<L, B>? {
        { opt in opt.flatMapT(fn) }
    }
}
