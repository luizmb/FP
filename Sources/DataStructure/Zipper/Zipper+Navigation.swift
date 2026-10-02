// SPDX-License-Identifier: Apache-2.0

// MARK: - Navigation

public extension Zipper {
    /// Move the focus one step to the left. Returns `nil` when already ``Zipper/isAtStart``.
    ///
    /// O(1): the new zipper shares ``Zipper/elements`` with this one; only the index moves.
    func moveLeft() -> Zipper<A>? {
        isAtStart ? nil : Zipper(uncheckedElements: elements, focusedIndex: focusedIndex - 1)
    }

    /// Move the focus one step to the right. Returns `nil` when already ``Zipper/isAtEnd``.
    ///
    /// O(1): the new zipper shares ``Zipper/elements`` with this one; only the index moves.
    func moveRight() -> Zipper<A>? {
        isAtEnd ? nil : Zipper(uncheckedElements: elements, focusedIndex: focusedIndex + 1)
    }

    /// The full sequence in natural order. O(1): returns the shared ``Zipper/elements``.
    func toArray() -> [A] {
        elements
    }
}

// MARK: - Free functions

/// Convert a `Zipper` to a plain `Array` — point-free friendly.
public func toArray<A>(_ z: Zipper<A>) -> [A] {
    z.toArray()
}
