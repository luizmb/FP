import Foundation
import FP

// EitherTArray: outer = Either, inner = Array
// Type: Either<L, [A]> = Either<L, Array<A>>
// Haskell: ListT (Either L)

/// flatMapT for Either<L, [A]>
/// .left(l)    → .left(l)
/// .right(arr) → arr.map(fn) reduced into Either<L, [B]>
public func flatMapTEitherArray<L, A, B>(
    _ either: Either<L, [A]>,
    _ fn: @escaping (A) -> Either<L, [B]>
) -> Either<L, [B]> {
    either.flatMap { arr in
        arr.map(fn).reduce(.right([])) { acc, next in
            acc.flatMap { combined in next.mapRight { combined + $0 } }
        }
    }
}

/// Curried version
public func bindTEitherArray<L, A, B>(
    _ fn: @escaping (A) -> Either<L, [B]>
) -> (Either<L, [A]>) -> Either<L, [B]> {
    { either in flatMapTEitherArray(either, fn) }
}
