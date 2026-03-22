import DataStructure
import Core
import CoreOperators

// OptionalTEither: outer = Optional, inner = Either
// Type: Either<L,A>? = Optional<Either<L,A>>

// (<*>) :: Either<l,(a->b)>? -> Either<l,a>? -> Either<l,b>?
public func <*> <L, A, B>(_ fns: Either<L, (A) -> B>?, _ values: Either<L, A>?) -> Either<L, B>? {
    applyOptionalEither(fns, values)
}

// (*>) :: Either<l,a>? -> Either<l,b>? -> Either<l,b>?
public func *> <L, A, B>(_ lhs: Either<L, A>?, _ rhs: Either<L, B>?) -> Either<L, B>? {
    seqRightOptionalEither(lhs, rhs)
}

// (<*) :: Either<l,a>? -> Either<l,b>? -> Either<l,a>?
public func <* <L, A, B>(_ lhs: Either<L, A>?, _ rhs: Either<L, B>?) -> Either<L, A>? {
    seqLeftOptionalEither(lhs, rhs)
}
