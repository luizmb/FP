// SPDX-License-Identifier: Apache-2.0

// MARK: - NonEmpty interop

public extension Zipper {
    /// Build a `Zipper` focused at the head of a `NonEmpty`, with the rest of its
    /// elements placed to the right of the focus.
    static func fromNonEmpty(_ ne: NonEmpty<A>) -> Zipper<A> {
        Zipper(uncheckedElements: ne.toArray, focusedIndex: 0)
    }

    /// Reconstruct a `NonEmpty` from the zipper's full sequence (``toArray()``),
    /// regardless of where the focus currently sits.
    func toNonEmpty() -> NonEmpty<A> {
        NonEmpty(head: elements[elements.startIndex], tail: Array(elements.dropFirst()))
    }
}
