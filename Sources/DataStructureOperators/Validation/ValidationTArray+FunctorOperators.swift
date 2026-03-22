import DataStructure
import CoreFPOperators
import CoreFP

// (<£^>) :: (a -> b) -> Validation<e, [a]> -> Validation<e, [b]>
public func <£^> <E: Semigroup, A, B>(_ fn: @escaping (A) -> B, _ v: Validation<E, [A]>) -> Validation<E, [B]> {
    fmapTValidationArray(fn)(v)
}

// (<&^>) :: Validation<e, [a]> -> (a -> b) -> Validation<e, [b]>
public func <&^> <E: Semigroup, A, B>(_ v: Validation<E, [A]>, _ fn: @escaping (A) -> B) -> Validation<E, [B]> {
    fmapTValidationArray(fn)(v)
}
