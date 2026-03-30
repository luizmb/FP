import CoreFP
import CoreFPOperators
import DataStructure

// (<£^>) :: (a -> b) -> Validation<e, Writer<w, a>> -> Validation<e, Writer<w, b>>
public func <£^> <E: Semigroup, W: Monoid, A, B>(
    _ fn: @escaping (A) -> B,
    _ v: Validation<E, Writer<W, A>>
) -> Validation<E, Writer<W, B>> {
    fmapTValidationWriter(fn)(v)
}

// (<&^>) :: Validation<e, Writer<w, a>> -> (a -> b) -> Validation<e, Writer<w, b>>
public func <&^> <E: Semigroup, W: Monoid, A, B>(
    _ v: Validation<E, Writer<W, A>>,
    _ fn: @escaping (A) -> B
) -> Validation<E, Writer<W, B>> {
    fmapTValidationWriter(fn)(v)
}
