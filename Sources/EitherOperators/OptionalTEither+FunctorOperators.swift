import FP
import Either
import Operators

// OptionalTEither: outer = Optional, inner = Either
// Type: Either<L,A>? = Optional<Either<L,A>>

// (<£>) :: (a -> b) -> Either<l,a>? -> Either<l,b>?
public func <£> <L, A, B>(_ fn: @escaping (A) -> B, _ opt: Either<L, A>?) -> Either<L, B>? {
    opt.mapT(fn)
}

// (<&>) :: Either<l,a>? -> (a -> b) -> Either<l,b>?
public func <&> <L, A, B>(_ opt: Either<L, A>?, _ fn: @escaping (A) -> B) -> Either<L, B>? {
    opt.mapT(fn)
}
