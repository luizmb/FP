// SPDX-License-Identifier: Apache-2.0
import CoreFP

public extension Validation {
    /// Alt: the first success; when both fail, the errors accumulate (`e1 <> e2`), as in
    /// Haskell's `Alt (Validation e)` (e.g. purescript-validation). `rhs` is only evaluated
    /// when `lhs` fails.
    /// (<|>) :: Validation e a -> Validation e a -> Validation e a
    static func alt(_ lhs: Validation<E, A>, _ rhs: @autoclosure () -> Validation<E, A>) -> Validation<E, A> {
        switch lhs {
        case .success:
            lhs

        case let .failure(e1):
            rhs().mapFailure { e2 in E.combine(e1, e2) }
        }
    }
}
