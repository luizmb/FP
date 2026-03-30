import CoreFPOperators
import DataStructure

// (<*>) :: Stateful<s, Either<l, (a -> b)>> -> Stateful<s, Either<l, a>> -> Stateful<s, Either<l, b>>
public func <*> <S, L, A, B>(_ sf: Stateful<S, Either<L, (A) -> B>>, _ sa: Stateful<S, Either<L, A>>) -> Stateful<S, Either<L, B>> {
    applyStatefulEither(sf, sa)
}

// (*>) :: Stateful<s, Either<l, a>> -> Stateful<s, Either<l, b>> -> Stateful<s, Either<l, b>>
public func *> <S, L, A, B>(_ lhs: Stateful<S, Either<L, A>>, _ rhs: Stateful<S, Either<L, B>>) -> Stateful<S, Either<L, B>> {
    seqRightStatefulEither(lhs, rhs)
}

// (<*) :: Stateful<s, Either<l, a>> -> Stateful<s, Either<l, b>> -> Stateful<s, Either<l, a>>
public func <* <S, L, A, B>(_ lhs: Stateful<S, Either<L, A>>, _ rhs: Stateful<S, Either<L, B>>) -> Stateful<S, Either<L, A>> {
    seqLeftStatefulEither(lhs, rhs)
}
