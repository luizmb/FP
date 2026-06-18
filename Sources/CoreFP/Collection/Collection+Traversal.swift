// SPDX-License-Identifier: Apache-2.0

// MARK: - Collection traversals (`each`)

//
// `each` is to `Traversal` what `ix` is to `AffineTraversal`: it focuses on
// *every* element of a collection (or every value of a dictionary) at once.
//
//   - `MutableCollection.each` mutates each element via `inout collection[i]`,
//     which is zero-copy — the buffer is never CoW-copied.
//   - `Dictionary.eachValue` copies each `Value` once (the subscript has no
//     in-place mutation path), mirroring `ix(key:)`.

public extension MutableCollection where Element: Sendable {
    /// A ``Traversal`` focusing on **every** element of the collection.
    ///
    /// `modifyMut` walks the indices and mutates each element directly via
    /// `inout collection[i]` — zero-copy on the buffer.
    ///
    /// ```swift
    /// [Int].each.getAll([10, 20, 30])          // [10, 20, 30]
    /// [Int].each.over { $0 * 2 }([10, 20, 30]) // [20, 40, 60]
    /// ```
    static var each: Traversal<Self, Element> {
        Traversal(
            getAll: { @Sendable in Array($0) },
            modifyMut: { @Sendable collection, f in
                var i = collection.startIndex
                while i != collection.endIndex {
                    f(&collection[i])
                    i = collection.index(after: i)
                }
            }
        )
    }
}

public extension Dictionary where Key: Sendable, Value: Sendable {
    /// A ``Traversal`` focusing on **every** value of the dictionary.
    ///
    /// `modifyMut` copies each `Value` once (extracted from the subscript), then writes it back —
    /// mirroring ``ix(key:)``. Key order follows the dictionary's own iteration order.
    ///
    /// ```swift
    /// [String: Int].eachValue.over { $0 + 1 }(["a": 1, "b": 2])   // ["a": 2, "b": 3]
    /// ```
    static var eachValue: Traversal<[Key: Value], Value> {
        Traversal(
            getAll: { @Sendable in Array($0.values) },
            modifyMut: { @Sendable dict, f in
                for key in dict.keys {
                    guard var value = dict[key] else { continue }
                    f(&value)
                    dict[key] = value
                }
            }
        )
    }
}

public extension MutableCollection where Index: Sendable, Element: Sendable {
    /// An ``IndexedTraversal`` focusing on every element, tagged with its collection index.
    ///
    /// ```swift
    /// [String].eachIndexed.getAll(["a", "b"])   // [(0, "a"), (1, "b")]
    /// ```
    static var eachIndexed: IndexedTraversal<Self, Index, Element> {
        IndexedTraversal(
            getAll: { @Sendable collection in collection.indices.map { ($0, collection[$0]) } },
            modifyMut: { @Sendable collection, f in
                var i = collection.startIndex
                while i != collection.endIndex {
                    f(i, &collection[i])
                    i = collection.index(after: i)
                }
            }
        )
    }
}

public extension Dictionary where Key: Sendable, Value: Sendable {
    /// An ``IndexedTraversal`` focusing on every value, tagged with its key.
    ///
    /// ```swift
    /// [String: Int].eachValueIndexed.over { key, v in key == "a" ? v : 0 }(["a": 1, "b": 2])
    /// // ["a": 1, "b": 0]
    /// ```
    static var eachValueIndexed: IndexedTraversal<[Key: Value], Key, Value> {
        IndexedTraversal(
            getAll: { @Sendable dict in dict.map { ($0.key, $0.value) } },
            modifyMut: { @Sendable dict, f in
                for key in dict.keys {
                    guard var value = dict[key] else { continue }
                    f(key, &value)
                    dict[key] = value
                }
            }
        )
    }
}
