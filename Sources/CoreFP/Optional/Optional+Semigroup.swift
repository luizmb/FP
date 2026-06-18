// SPDX-License-Identifier: Apache-2.0
extension Optional: Semigroup where Wrapped: Semigroup {
    /// Combines two optionals: merges the wrapped values if both are present,
    /// otherwise returns whichever side is non-nil.
    public static func combine(_ lhs: Wrapped?, _ rhs: Wrapped?) -> Wrapped? {
        switch (lhs, rhs) {
        case let (.some(l), .some(r)):
            .some(Wrapped.combine(l, r))

        case (.some, .none):
            lhs

        case (.none, .some):
            rhs

        case (.none, .none):
            .none
        }
    }
}

extension Optional: Monoid where Wrapped: Monoid {
    public static var identity: Wrapped? { .none }
}
