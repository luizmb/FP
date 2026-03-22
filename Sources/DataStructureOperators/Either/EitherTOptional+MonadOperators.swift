import DataStructure
import CoreFP
import CoreFPOperators

// EitherTOptional: outer = Either, inner = Optional
// Type: Either<L, A?>

// (>>-) :: Either<l,a?> -> (a -> Either<l,b?>) -> Either<l,b?>
public func >>- <L, A, B>(_ either: Either<L, A?>, _ fn: @escaping (A) -> Either<L, B?>) -> Either<L, B?> {
    flatMapTEitherOptional(either, fn)
}

// (-<<) :: (a -> Either<l,b?>) -> Either<l,a?> -> Either<l,b?>
public func -<< <L, A, B>(_ fn: @escaping (A) -> Either<L, B?>, _ either: Either<L, A?>) -> Either<L, B?> {
    flatMapTEitherOptional(either, fn)
}

// (>=>) :: (a -> Either<l,b?>) -> (b -> Either<l,c?>) -> a -> Either<l,c?>
public func >=> <L, A, B, C>(
    _ fn1: @escaping (A) -> Either<L, B?>,
    _ fn2: @escaping (B) -> Either<L, C?>
) -> (A) -> Either<L, C?> {
    { a in flatMapTEitherOptional(fn1(a), fn2) }
}
