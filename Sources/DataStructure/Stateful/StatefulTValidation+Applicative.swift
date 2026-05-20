import CoreFP

// StatefulTValidation: outer = Stateful, inner = Validation
// Type: Stateful<S, Validation<E, A>>
// Threads state sequentially; accumulates Validation errors across both branches.

public func applyStatefulValidation<S, E: Semigroup, A, B>(
    _ sf: Stateful<S, Validation<E, (A) -> B>>,
    _ sa: Stateful<S, Validation<E, A>>
) -> Stateful<S, Validation<E, B>> {
    Stateful<S, Validation<E, B>> { s in
        Validation.apply(sf.run(&s), sa.run(&s))
    }
}

public func liftA2StatefulValidation<S, E: Semigroup, A, B, C>(
    _ fn: @escaping @Sendable (A, B) -> C
) -> (Stateful<S, Validation<E, A>>, Stateful<S, Validation<E, B>>) -> Stateful<S, Validation<E, C>> {
    { sa, sb in
        Stateful<S, Validation<E, C>> { s in
            Validation.liftA2(fn)(sa.run(&s), sb.run(&s))
        }
    }
}

public func seqRightStatefulValidation<S, E: Semigroup, A, B>(
    _ lhs: Stateful<S, Validation<E, A>>,
    _ rhs: Stateful<S, Validation<E, B>>
) -> Stateful<S, Validation<E, B>> {
    Stateful<S, Validation<E, B>> { s in lhs.run(&s).seqRight(rhs.run(&s)) }
}

public func seqLeftStatefulValidation<S, E: Semigroup, A, B>(
    _ lhs: Stateful<S, Validation<E, A>>,
    _ rhs: Stateful<S, Validation<E, B>>
) -> Stateful<S, Validation<E, A>> {
    Stateful<S, Validation<E, A>> { s in lhs.run(&s).seqLeft(rhs.run(&s)) }
}
