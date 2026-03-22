import CoreFP

// ValidationTWriter: outer = Validation, inner = Writer
// Type: Validation<E, Writer<W, A>>

public func fmapTValidationWriter<E: Semigroup, W: Monoid, A, B>(
    _ fn: @escaping (A) -> B
) -> (Validation<E, Writer<W, A>>) -> Validation<E, Writer<W, B>> {
    { $0.mapSuccess { writer in writer.fmap(fn) } }
}
