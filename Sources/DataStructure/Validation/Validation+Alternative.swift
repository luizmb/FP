// SPDX-License-Identifier: Apache-2.0
import CoreFP

public extension Validation {
    /// Alternative operation — returns the first Success, or the rhs if lhs is Failure.
    /// (<|>) :: Validation e a -> Validation e a -> Validation e a
    static func alt(_ lhs: Validation<E, A>, _ rhs: @autoclosure () -> Validation<E, A>) -> Validation<E, A> {
        lhs.match(
            caseFailure: const(rhs()),
            caseSuccess: const(lhs)
        )
    }
}
