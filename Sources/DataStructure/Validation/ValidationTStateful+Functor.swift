import CoreFP

// ValidationTStateful: outer = Validation, inner = Stateful
// Type: Validation<E, Stateful<S, A>>

public func fmapTValidationStateful<E: Semigroup, S, A, B>(
    _ fn: @escaping @Sendable (A) -> B
) -> (Validation<E, Stateful<S, A>>) -> Validation<E, Stateful<S, B>> {
    { $0.mapSuccess { stateful in stateful.mapStateful(fn) } }
}
