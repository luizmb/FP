// SPDX-License-Identifier: Apache-2.0

// MARK: - NonEmpty interop

public extension Zipper {
    /// Build a `Zipper` focused at the head of a `NonEmpty`, with the rest of its
    /// elements placed to the right of the focus.
    static func fromNonEmpty(_ ne: NonEmpty<A>) -> Zipper<A> {
        Zipper(left: [], focus: ne.head, right: ne.tail)
    }

    /// Reconstruct a `NonEmpty` from the zipper's full sequence (``toArray()``),
    /// regardless of where the focus currently sits.
    func toNonEmpty() -> NonEmpty<A> {
        let full = toArray()
        return NonEmpty(head: full[0], tail: Array(full.dropFirst()))
    }
}
