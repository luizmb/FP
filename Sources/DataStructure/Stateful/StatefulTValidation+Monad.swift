import CoreFP

// StatefulTValidation: outer = Stateful, inner = Validation
// Type: Stateful<S, Validation<E, A>>
// flatMapT sequences state AND Validation — short-circuits on Validation failure.

public func flatMapTStatefulValidation<S, E: Semigroup, A, B>(
    _ stateful: Stateful<S, Validation<E, A>>,
    _ fn: @escaping (A) -> Stateful<S, Validation<E, B>>
) -> Stateful<S, Validation<E, B>> {
    Stateful<S, Validation<E, B>> { s in
        stateful.run(&s).match(
            caseFailure: Validation.failure,
            caseSuccess: { a in fn(a).run(&s) }
        )
    }
}

public func bindTStatefulValidation<S, E: Semigroup, A, B>(
    _ fn: @escaping (A) -> Stateful<S, Validation<E, B>>
) -> (Stateful<S, Validation<E, A>>) -> Stateful<S, Validation<E, B>> {
    { flatMapTStatefulValidation($0, fn) }
}
