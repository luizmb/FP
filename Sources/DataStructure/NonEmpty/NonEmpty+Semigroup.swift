// SPDX-License-Identifier: Apache-2.0
import CoreFP

// MARK: - Semigroup

// Two non-empty sequences always concatenate into a non-empty sequence.
// NonEmpty deliberately does NOT conform to Monoid: there is no empty NonEmpty<A>.

extension NonEmpty: Semigroup {
    public static func combine(_ lhs: NonEmpty<A>, _ rhs: NonEmpty<A>) -> NonEmpty<A> {
        NonEmpty(head: lhs.head, tail: lhs.tail + rhs.toArray)
    }
}

// MARK: - sconcat convenience

/// Reduce a `NonEmpty` of `Semigroup` values using `combine`.
/// Works like `mconcat` but requires no identity element.
public func sconcat<A: Semigroup>(_ ne: NonEmpty<A>) -> A {
    CoreFP.sconcat(ne.head, ne.tail)
}
