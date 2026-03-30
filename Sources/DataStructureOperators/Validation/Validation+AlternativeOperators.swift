import CoreFP
import DataStructure
import CoreFPOperators

// (<|>) :: Validation e a -> Validation e a -> Validation e a
public func <|> <E: Semigroup, A>(_ lhs: Validation<E, A>, _ rhs: @autoclosure () -> Validation<E, A>) -> Validation<E, A> {
    Validation.alt(lhs, rhs())
}
