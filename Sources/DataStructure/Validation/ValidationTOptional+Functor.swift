import CoreFP

// ValidationTOptional: outer = Validation, inner = Optional
// Type: Validation<E, A?>

public func fmapTValidationOptional<E: Semigroup, A, B>(
    _ fn: @escaping (A) -> B
) -> (Validation<E, A?>) -> Validation<E, B?> {
    { $0.mapSuccess { $0.map(fn) } }
}
