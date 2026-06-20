// SPDX-License-Identifier: Apache-2.0

// MARK: - IdentifiedArray: RandomAccessCollection

//
// Order lives entirely in the element buffer, so positional access is a direct
// passthrough to `storage`. Integer-indexed, like `Array`. Lookup by identifier
// is a separate O(1) path (`subscript(id:)`), not part of the `Collection`
// surface, so positional and identified access never interfere.

extension IdentifiedArray: RandomAccessCollection {
    public typealias Index = Int

    @inlinable
    public var startIndex: Int { storage.startIndex }

    @inlinable
    public var endIndex: Int { storage.endIndex }

    @inlinable
    public func index(after i: Int) -> Int { storage.index(after: i) }

    @inlinable
    public func index(before i: Int) -> Int { storage.index(before: i) }

    /// Positional access (read-only). For by-id access use ``subscript(id:)``.
    @inlinable
    public subscript(position: Int) -> Element { storage[position] }
}
