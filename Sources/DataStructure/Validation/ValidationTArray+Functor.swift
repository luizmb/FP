import CoreFP

// ValidationTArray: outer = Validation, inner = Array
// Type: Validation<E, [A]>

public func fmapTValidationArray<E: Semigroup, A, B>(
    _ fn: @escaping (A) -> B
) -> (Validation<E, [A]>) -> Validation<E, [B]> {
    { $0.mapSuccess { $0.map(fn) } }
}
