// SPDX-License-Identifier: Apache-2.0
import CoreFP

// Semigroup / Monoid — delegate to RawValue. The `<>` operator (defined on Semigroup in CoreFP)
// works on Newtype for free because the conformance reuses RawValue's combine.

extension Newtype: Semigroup where RawValue: Semigroup {
    public static func combine(_ lhs: Self, _ rhs: Self) -> Self {
        Self(RawValue.combine(lhs.rawValue, rhs.rawValue))
    }
}

extension Newtype: Monoid where RawValue: Monoid {
    public static var identity: Self { Self(RawValue.identity) }
}
