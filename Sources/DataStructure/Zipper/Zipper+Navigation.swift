// SPDX-License-Identifier: Apache-2.0

// MARK: - Navigation

public extension Zipper {
    /// Move the focus one step to the left. Returns `nil` when already ``Zipper/isAtStart``.
    ///
    /// The first element of ``left`` becomes the new focus, and the old focus is
    /// pushed onto the front of ``right``.
    func moveLeft() -> Zipper<A>? {
        guard let newFocus = left.first else { return nil }
        return Zipper(left: Array(left.dropFirst()), focus: newFocus, right: [focus] + right)
    }

    /// Move the focus one step to the right. Returns `nil` when already ``Zipper/isAtEnd``.
    ///
    /// The first element of ``right`` becomes the new focus, and the old focus is
    /// pushed onto the front of ``left``.
    func moveRight() -> Zipper<A>? {
        guard let newFocus = right.first else { return nil }
        return Zipper(left: [focus] + left, focus: newFocus, right: Array(right.dropFirst()))
    }

    /// The full sequence in natural order: ``left`` (un-reversed), the ``focus``, then ``right``.
    func toArray() -> [A] {
        left.reversed() + [focus] + right
    }
}

// MARK: - Free functions

/// Convert a `Zipper` to a plain `Array` — point-free friendly.
public func toArray<A>(_ z: Zipper<A>) -> [A] {
    z.toArray()
}
