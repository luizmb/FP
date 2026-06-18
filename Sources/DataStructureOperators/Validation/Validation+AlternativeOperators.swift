// SPDX-License-Identifier: Apache-2.0
import CoreFP
import CoreFPOperators
import DataStructure

/// (<|>) :: Validation e a -> Validation e a -> Validation e a
public func <|> <E: Semigroup, A>(_ lhs: Validation<E, A>, _ rhs: @autoclosure () -> Validation<E, A>) -> Validation<E, A> {
    Validation.alt(lhs, rhs())
}
