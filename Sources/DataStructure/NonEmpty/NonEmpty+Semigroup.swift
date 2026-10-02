// SPDX-License-Identifier: Apache-2.0
import CoreFP

// MARK: - Semigroup

// Two non-empty sequences always concatenate into a non-empty sequence.
// NonEmpty deliberately does NOT conform to Monoid: there is no empty NonEmpty<A>.

extension NonEmpty: Semigroup {
    public static func combine(_ lhs: NonEmpty<A>, _ rhs: NonEmpty<A>) -> NonEmpty<A> {
        NonEmpty(head: lhs.head, tail: lhs.tail + rhs.toArray)
    }

    /// Single-pass fold: the tail is built once with its final capacity, so concatenating
    /// `n` values is O(total elements) instead of the default left fold's O(n²) copying.
    public static func sconcat(_ first: NonEmpty<A>, _ rest: [NonEmpty<A>]) -> NonEmpty<A> {
        var tail = first.tail
        tail.reserveCapacity(rest.reduce(into: first.tail.count) { $0 += 1 + $1.tail.count })
        for next in rest {
            tail.append(next.head)
            tail.append(contentsOf: next.tail)
        }
        return NonEmpty(head: first.head, tail: tail)
    }
}

// MARK: - sconcat convenience

/// Reduce a `NonEmpty` of `Semigroup` values using `combine`.
/// Works like `mconcat` but requires no identity element.
public func sconcat<A: Semigroup>(_ ne: NonEmpty<A>) -> A {
    CoreFP.sconcat(ne.head, ne.tail)
}
