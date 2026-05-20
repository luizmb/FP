import Foundation

// StatefulT + Either — free functions for Stateful<S, Either<L, A>>

/// apply for Stateful<S, Either>
public func applyStatefulEither<S, L: Sendable, A: Sendable, B: Sendable>(
    _ sf: Stateful<S, Either<L, @Sendable (A) -> B>>,
    _ sa: Stateful<S, Either<L, A>>
) -> Stateful<S, Either<L, B>> {
    Stateful<S, Either<L, B>> { s in
        let fOrL = sf.run(&s)
        let aOrL = sa.run(&s)
        return fOrL.flatMap { @Sendable f in aOrL.mapRight(f) }
    }
}

/// liftA2 for Stateful<S, Either>
public func liftA2StatefulEither<S, L, A, B, C>(
    _ fn: @escaping @Sendable (A, B) -> C
) -> (Stateful<S, Either<L, A>>, Stateful<S, Either<L, B>>) -> Stateful<S, Either<L, C>> {
    { sa, sb in
        Stateful<S, Either<L, C>> { s in
            Either.liftA2(fn)(sa.run(&s), sb.run(&s))
        }
    }
}

/// seqRight for Stateful<S, Either>
public func seqRightStatefulEither<S, L: Sendable, A: Sendable, B: Sendable>(
    _ lhs: Stateful<S, Either<L, A>>,
    _ rhs: Stateful<S, Either<L, B>>
) -> Stateful<S, Either<L, B>> {
    Stateful<S, Either<L, B>> { s in lhs.run(&s).seqRight(rhs.run(&s)) }
}

/// seqLeft for Stateful<S, Either>
public func seqLeftStatefulEither<S, L: Sendable, A: Sendable, B: Sendable>(
    _ lhs: Stateful<S, Either<L, A>>,
    _ rhs: Stateful<S, Either<L, B>>
) -> Stateful<S, Either<L, A>> {
    Stateful<S, Either<L, A>> { s in lhs.run(&s).seqLeft(rhs.run(&s)) }
}
