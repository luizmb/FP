import CoreFP
import CoreFPOperators
import DataStructure

// (<*>) :: Validation<e, (a -> b)> -> Validation<e, a> -> Validation<e, b>
public func <*> <E: Semigroup, A, B>(_ fns: Validation<E, @Sendable (A) -> B>, _ values: Validation<E, A>) -> Validation<E, B> {
    Validation<E, B>.apply(fns, values)
}

// (*>) :: Validation<e, a> -> Validation<e, b> -> Validation<e, b>
public func *> <E: Semigroup, A, B>(_ lhs: Validation<E, A>, _ rhs: Validation<E, B>) -> Validation<E, B> {
    lhs.seqRight(rhs)
}

// (<*) :: Validation<e, a> -> Validation<e, b> -> Validation<e, a>
public func <* <E: Semigroup, A, B>(_ lhs: Validation<E, A>, _ rhs: Validation<E, B>) -> Validation<E, A> {
    lhs.seqLeft(rhs)
}
