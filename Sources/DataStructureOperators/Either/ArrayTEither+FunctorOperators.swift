import DataStructure
import Core
import CoreOperators

// ArrayTEither: outer = Array, inner = Either
// Type: [Either<L,A>]

// (<£>) :: (a -> b) -> [Either<l,a>] -> [Either<l,b>]
public func <£> <L, A, B>(_ fn: @escaping (A) -> B, _ arr: [Either<L, A>]) -> [Either<L, B>] {
    arr.mapT(fn)
}

// (<&>) :: [Either<l,a>] -> (a -> b) -> [Either<l,b>]
public func <&> <L, A, B>(_ arr: [Either<L, A>], _ fn: @escaping (A) -> B) -> [Either<L, B>] {
    arr.mapT(fn)
}
