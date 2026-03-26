import CoreFP

// ValidationTNonEmpty: outer = Validation, inner = NonEmpty
// Type: Validation<E, NonEmpty<A>>

public func fmapTValidationNonEmpty<E: Semigroup, A, B>(
    _ fn: @escaping (A) -> B
) -> (Validation<E, NonEmpty<A>>) -> Validation<E, NonEmpty<B>> {
    { $0.mapSuccess { $0.map(fn) } }
}
