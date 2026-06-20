// SPDX-License-Identifier: Apache-2.0
import CoreFP

// MARK: - Semigroup

// Combining two identified arrays appends the right-hand elements into the
// left-hand one with last-wins semantics on duplicate ids: an id already present
// keeps its left-hand position but takes the right-hand value (mirroring
// `append`). This is associative — id *position* is fixed by first appearance
// across the operands, and id *value* by last appearance — so the ``Semigroup``
// laws hold.
//
// Like ``NonEmpty``, the conformance is unconditional: `Semigroup` refines the
// marker protocol `Sendable`, so a conditional `where ID: Sendable` clause is
// rejected. The left operand's `id` closure keys the result.

extension IdentifiedArray: Semigroup {
    public static func combine(_ lhs: Self, _ rhs: Self) -> Self {
        var result = lhs
        var i = 0
        while i < rhs.storage.count {
            result.append(rhs.storage[i])
            i &+= 1
        }
        return result
    }
}

// MARK: - Lawful surface (why there is no Functor / Applicative / Monad)

//
// `Semigroup` is the ONLY standard algebra `IdentifiedArray` conforms to. The
// rest are deliberately absent, for two compounding reasons:
//
//  1. Value-dependent collapse is not structure-preserving. A lawful (parametric)
//     `Functor` may not change the collection's count; an element-type-changing
//     `map` that re-keys can collapse duplicate ids (last-wins), shrinking the
//     count — so it is not a lawful functor. `Applicative`/`Monad` would need
//     free concatenation, producing duplicate ids the type forbids; collapsing to
//     restore uniqueness breaks their laws too. (This is also why `Set` is not a
//     `Functor` and why pointfree's `IdentifiedArray` ships none of these.)
//
//  2. The value carries its own key (for the `Identifiable` form, `element.id`),
//     so an independent key/value `bimap` could desync them. Deriving the key
//     from the value avoids that, but lands back on case 1.
//
// `Monoid` is absent for a third reason: the identity is the empty collection,
// but `static var identity` cannot supply the `id` closure an arbitrary `Element`
// needs. Fold non-empty runs with `sconcat`.
//
// Sanctioned path for value transforms (fully lawful): operate on `.elements`
// (the `Array` functor/monad), then rebuild with `dedupPrism` (which surfaces id
// collisions) or `arrayIso` (last-wins normalise). In-place, same-identity edits
// stay on the type via `subscript(id:)`, `ix(id:)`, and the `traversed` optic.
