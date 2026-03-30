import Foundation

// EitherTArray: outer = Either, inner = Array
// Type: Either<L, [A]> = Either<L, Array<A>>

/// mapT for Either<L, [A]>
public func mapTEitherArray<L, A, B>(
    _ fn: @escaping (A) -> B,
    _ either: Either<L, [A]>
) -> Either<L, [B]> {
    either.mapRight { arr in arr.map(fn) }
}

/// Curried fmapT
public func fmapTEitherArray<L, A, B>(
    _ fn: @escaping (A) -> B
) -> (Either<L, [A]>) -> Either<L, [B]> {
    { either in mapTEitherArray(fn, either) }
}
