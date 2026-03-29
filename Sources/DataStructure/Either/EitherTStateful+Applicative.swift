import CoreFP
import Foundation

// EitherTStateful: outer = Either, inner = Stateful
// Type: Either<L, Stateful<S, A>>

/// apply for EitherTStateful: Either<L,Stateful<S,(A->B)>> -> Either<L,Stateful<S,A>> -> Either<L,Stateful<S,B>>
public func applyEitherStateful<L, S, A, B>(
    _ eithF: Either<L, Stateful<S, (A) -> B>>,
    _ eithA: Either<L, Stateful<S, A>>
) -> Either<L, Stateful<S, B>> {
    Either.liftA2 { sf, sa in Stateful<S, B>.apply(sf, sa) }(eithF, eithA)
}

/// liftA2 for EitherTStateful
public func liftA2EitherStateful<L, S, A, B, C>(
    _ fn: @escaping (A, B) -> C
) -> (Either<L, Stateful<S, A>>, Either<L, Stateful<S, B>>) -> Either<L, Stateful<S, C>> {
    { ea, eb in
        Either.liftA2 { sa, sb in Stateful<S, C> { s in fn(sa.run(&s), sb.run(&s)) } }(ea, eb)
    }
}

/// seqRight for EitherTStateful
public func seqRightEitherStateful<L, S, A, B>(
    _ lhs: Either<L, Stateful<S, A>>,
    _ rhs: Either<L, Stateful<S, B>>
) -> Either<L, Stateful<S, B>> {
    Either.liftA2 { sa, sb in sa.seqRight(sb) }(lhs, rhs)
}

/// seqLeft for EitherTStateful
public func seqLeftEitherStateful<L, S, A, B>(
    _ lhs: Either<L, Stateful<S, A>>,
    _ rhs: Either<L, Stateful<S, B>>
) -> Either<L, Stateful<S, A>> {
    Either.liftA2 { sa, sb in sa.seqLeft(sb) }(lhs, rhs)
}
