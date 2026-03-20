import FP
import Either
import Operators

// EitherTArray: outer = Either, inner = Array
// Type: Either<L, [A]>

// (<£>) :: (a -> b) -> Either<l,[a]> -> Either<l,[b]>
public func <£> <L, A, B>(_ fn: @escaping (A) -> B, _ either: Either<L, [A]>) -> Either<L, [B]> {
    fmapTEitherArray(fn)(either)
}

// (<&>) :: Either<l,[a]> -> (a -> b) -> Either<l,[b]>
public func <&> <L, A, B>(_ either: Either<L, [A]>, _ fn: @escaping (A) -> B) -> Either<L, [B]> {
    fmapTEitherArray(fn)(either)
}
