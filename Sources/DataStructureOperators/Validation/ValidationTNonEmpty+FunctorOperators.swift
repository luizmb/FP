import DataStructure
import CoreFPOperators
import CoreFP

// ValidationTNonEmpty: outer = Validation, inner = NonEmpty
// Type: Validation<E, NonEmpty<A>>

// (<£^>) :: (A -> B) -> Validation<E, NonEmpty<A>> -> Validation<E, NonEmpty<B>>
public func <£^> <E: Semigroup, A, B>(_ fn: @escaping (A) -> B, _ v: Validation<E, NonEmpty<A>>) -> Validation<E, NonEmpty<B>> {
    fmapTValidationNonEmpty(fn)(v)
}

// (<&^>) :: Validation<E, NonEmpty<A>> -> (A -> B) -> Validation<E, NonEmpty<B>>
public func <&^> <E: Semigroup, A, B>(_ v: Validation<E, NonEmpty<A>>, _ fn: @escaping (A) -> B) -> Validation<E, NonEmpty<B>> {
    fmapTValidationNonEmpty(fn)(v)
}
