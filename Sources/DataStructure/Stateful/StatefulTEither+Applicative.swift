import Foundation
import CoreFP

// StatefulT + Either — free functions for Stateful<S, Either<L, A>>

/// apply for Stateful<S, Either>
public func applyStatefulEither<S, L, A, B>(
    _ sf: Stateful<S, Either<L, (A) -> B>>,
    _ sa: Stateful<S, Either<L, A>>
) -> Stateful<S, Either<L, B>> {
    Stateful<S, Either<L, B>> { s in
        sf.run(&s).flatMap(sa.run(&s).mapRight)
    }
}

/// liftA2 for Stateful<S, Either>
public func liftA2StatefulEither<S, L, A, B, C>(
    _ fn: @escaping (A, B) -> C
) -> (Stateful<S, Either<L, A>>, Stateful<S, Either<L, B>>) -> Stateful<S, Either<L, C>> {
    { sa, sb in
        Stateful<S, Either<L, C>> { s in
            Either.liftA2(fn)(sa.run(&s), sb.run(&s))
        }
    }
}

/// seqRight for Stateful<S, Either>
public func seqRightStatefulEither<S, L, A, B>(
    _ lhs: Stateful<S, Either<L, A>>,
    _ rhs: Stateful<S, Either<L, B>>
) -> Stateful<S, Either<L, B>> {
    Stateful<S, Either<L, B>> { s in lhs.run(&s).seqRight(rhs.run(&s)) }
}

/// seqLeft for Stateful<S, Either>
public func seqLeftStatefulEither<S, L, A, B>(
    _ lhs: Stateful<S, Either<L, A>>,
    _ rhs: Stateful<S, Either<L, B>>
) -> Stateful<S, Either<L, A>> {
    Stateful<S, Either<L, A>> { s in lhs.run(&s).seqLeft(rhs.run(&s)) }
}
