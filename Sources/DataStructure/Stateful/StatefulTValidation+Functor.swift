import CoreFP

// StatefulTValidation: outer = Stateful, inner = Validation
// Type: Stateful<S, Validation<E, A>>

public func fmapTStatefulValidation<S, E: Semigroup, A, B>(
    _ fn: @escaping (A) -> B,
    _ stateful: Stateful<S, Validation<E, A>>
) -> Stateful<S, Validation<E, B>> {
    stateful.mapStateful(Validation<E, A>.fmap(fn))
}

public func fmapTStatefulValidation<S, E: Semigroup, A, B>(
    _ fn: @escaping (A) -> B
) -> (Stateful<S, Validation<E, A>>) -> Stateful<S, Validation<E, B>> {
    { fmapTStatefulValidation(fn, $0) }
}
