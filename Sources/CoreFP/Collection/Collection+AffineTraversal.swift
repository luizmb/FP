// SPDX-License-Identifier: Apache-2.0
public extension MutableCollection where Index: Sendable {
    /// Returns an `AffineTraversal` focusing on the element at `index`.
    /// Preview returns `nil` when `index` is out of bounds; set is a no-op in that case.
    ///
    /// `tryModifyMut` accesses the element directly via `inout collection[index]`,
    /// which is zero-copy — the collection buffer is never CoW-copied. `Array`,
    /// `ContiguousArray` and `ArraySlice` get the `Indices == Range<Int>` overload, which
    /// goes through their buffer.
    ///
    /// ```swift
    /// [Int].ix(1).preview([10, 20, 30])        // Optional(20)
    /// [Int].ix(9).preview([10, 20, 30])        // nil
    /// [Int].ix(0).set([10, 20, 30], 99)        // [99, 20, 30]
    /// ```
    static func ix(_ index: Index) -> AffineTraversal<Self, Element> {
        AffineTraversal(
            preview: { @Sendable in $0[safe: index] },
            set: { @Sendable (collection: consuming Self, element: Element) in
                var copy = consume collection
                copy[safe: index] = element
                return copy
            },
            tryModifyMut: { @Sendable collection, f in
                guard collection.indices.contains(index) else { return }
                f(&collection[index])
            }
        )
    }
}

public extension MutableCollection where Indices == Range<Int> {
    /// ``ix(_:)`` for collections indexed by a plain `Int` range (`Array`, `ContiguousArray`,
    /// `ArraySlice`): contiguous storage is read and written through its buffer at offset
    /// `index - startIndex`, so neither goes through `Collection`'s subscript (whose accessor
    /// frame is heap-allocated when called from unspecialised code).
    ///
    /// ```swift
    /// [Int].ix(1).preview([10, 20, 30])                    // Optional(20)
    /// ArraySlice<Int>.ix(5).preview([0, 1, 2, 3, 4, 5][4...]) // Optional(5)
    /// ```
    static func ix(_ index: Int) -> AffineTraversal<Self, Element> {
        AffineTraversal(
            preview: { @Sendable collection in
                guard collection.indices.contains(index) else { return nil }
                let offset = index &- collection.startIndex
                return collection.withContiguousStorageIfAvailable { $0[offset] } ?? collection[index]
            },
            set: { @Sendable (collection: consuming Self, element: Element) in
                var copy = consume collection
                copy[safe: index] = element
                return copy
            },
            tryModifyMut: { @Sendable collection, f in
                guard collection.indices.contains(index) else { return }
                let offset = index &- collection.startIndex
                let mutated: Void? = collection.withContiguousMutableStorageIfAvailable { f(&$0[offset]) }
                guard mutated == nil else { return }
                f(&collection[index])
            }
        )
    }
}

public extension MutableCollection where Index: Sendable, Element: Sendable {
    /// Returns an `AffineTraversal` focusing on the first element whose field at `identifier`
    /// equals `id`. Use this when the element type is not `Identifiable` but has a stable
    /// `Hashable` field that uniquely identifies each element.
    ///
    /// `tryModifyMut` locates the element by linear search and then mutates it in place — the
    /// collection buffer is never CoW-copied. Contiguous collections are searched and written
    /// through their buffer, without a malloc per element scanned.
    ///
    /// ```swift
    /// struct Project { let slug: String; var title: String }
    /// [Project].ix(id: "auth", by: \.slug).preview(projects)?.title   // "Auth Module"
    /// ```
    static func ix<ID: Hashable & Sendable>(id: ID, by identifier: KeyPath<Element, ID>) -> AffineTraversal<Self, Element> {
        firstMatch { $0[keyPath: identifier] == id }
    }

    /// Returns an `AffineTraversal` focusing on the first element whose identifier closure
    /// returns a value equal to `id`. Prefer `ix(id:by:)` with a `KeyPath` when your type
    /// supports it; use this overload when the identifier is a computed property or requires
    /// a closure (e.g. SwiftRex lift rules that prohibit plain `KeyPath`).
    static func ix<ID: Hashable & Sendable>(
        id: ID,
        by identifier: @escaping @Sendable (Element) -> ID
    ) -> AffineTraversal<Self, Element> {
        firstMatch { identifier($0) == id }
    }
}

public extension MutableCollection where Element: Identifiable, Element.ID: Sendable, Index: Sendable {
    /// Returns an `AffineTraversal` focusing on the first element whose `id` matches.
    /// Preview returns `nil` when no element with that `id` exists; set is a no-op in that case.
    ///
    /// `tryModifyMut` mutates the element in place after a linear search — the collection
    /// buffer is never CoW-copied. Contiguous collections are searched and written through
    /// their buffer, without a malloc per element scanned.
    ///
    /// ```swift
    /// [Item].ix(id: 2).preview(items)?.name   // "B"
    /// [Item].ix(id: 99).preview(items)        // nil
    /// ```
    static func ix(id: Element.ID) -> AffineTraversal<Self, Element> {
        firstMatch { $0.id == id }
    }
}

extension MutableCollection where Index: Sendable {
    /// The affine traversal behind the `ix(id:)` family: the first element satisfying `isMatch`.
    ///
    /// Contiguous storage is searched, read and written through its buffer: called from code that
    /// can't be specialised, `Collection`'s subscript goes through a protocol witness whose accessor
    /// frame is heap-allocated, which `first(where:)` / `firstIndex(where:)` would pay for every
    /// element they scan. The search is read-only, so a miss never makes shared storage unique.
    static func firstMatch(_ isMatch: @escaping @Sendable (Element) -> Bool) -> AffineTraversal<Self, Element> {
        AffineTraversal(
            preview: { @Sendable collection in
                collection.withContiguousStorageIfAvailable { buffer in firstOffset(in: buffer, where: isMatch).map { buffer[$0] } }
                    ?? collection.first(where: isMatch)
            },
            set: { @Sendable (collection: consuming Self, element: Element) in
                var copy = consume collection
                copy.modifyFirst(where: isMatch) { $0 = element }
                return copy
            },
            tryModifyMut: { @Sendable collection, f in
                collection.modifyFirst(where: isMatch, f)
            }
        )
    }

    private mutating func modifyFirst(where isMatch: (Element) -> Bool, _ f: (inout Element) -> Void) {
        if let found = withContiguousStorageIfAvailable({ buffer in firstOffset(in: buffer, where: isMatch) }) {
            guard let offset = found else { return }
            let mutated: Void? = withContiguousMutableStorageIfAvailable { f(&$0[offset]) }
            guard mutated == nil else { return }
            f(&self[index(startIndex, offsetBy: offset)])
            return
        }
        guard let i = firstIndex(where: isMatch) else { return }
        f(&self[i])
    }
}

/// `buffer.firstIndex(where:)` as a plain loop: from unspecialised code the library method goes
/// through `Collection`'s subscript witness (a malloc per element), the loop through the buffer's
/// own subscript.
private func firstOffset<Element>(in buffer: UnsafeBufferPointer<Element>, where isMatch: (Element) -> Bool) -> Int? {
    var offset = 0
    while offset < buffer.count {
        if isMatch(buffer[offset]) { return offset }
        offset &+= 1
    }
    return nil
}

public extension Dictionary where Key: Sendable {
    /// Returns an `AffineTraversal` focusing on the value for `key`.
    /// Preview returns `nil` when the key is absent; set is a no-op in that case.
    ///
    /// `tryModifyMut` mutates the value in place through `dict.values[index]`: no copy of
    /// the value and no re-hashing.
    ///
    /// ```swift
    /// [String: Int].ix(key: "a").preview(["a": 1, "b": 2])   // Optional(1)
    /// [String: Int].ix(key: "z").preview(["a": 1, "b": 2])   // nil
    /// [String: Int].ix(key: "a").set(["a": 1, "b": 2], 99)   // ["a": 99, "b": 2]
    /// ```
    static func ix(key: Key) -> AffineTraversal<[Key: Value], Value> {
        AffineTraversal(
            preview: { @Sendable in $0[key] },
            set: { @Sendable (dict: consuming [Key: Value], value: Value) in
                guard let index = dict.index(forKey: key) else { return dict }
                var copy = consume dict
                copy.values[index] = value
                return copy
            },
            tryModifyMut: { @Sendable dict, f in
                guard let index = dict.index(forKey: key) else { return }
                f(&dict.values[index])
            }
        )
    }
}
