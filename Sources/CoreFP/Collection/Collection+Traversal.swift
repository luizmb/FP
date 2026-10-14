// SPDX-License-Identifier: Apache-2.0

// MARK: - Collection traversals (`each`)

//
// `each` is to `Traversal` what `ix` is to `AffineTraversal`: it focuses on
// *every* element of a collection (or every value of a dictionary) at once.
//
//   - `MutableCollection.each` mutates each element via `inout collection[i]`,
//     which is zero-copy — the buffer is never CoW-copied.
//   - `Dictionary.eachValue` mutates each value in place through one `inout`
//     access to `dict.values`, mirroring `ix(key:)`.
//   - `each`, and `eachIndexed` on `Range<Int>`-indexed collections, go through
//     the contiguous buffer when there is one (see `each` for why).

public extension MutableCollection where Element: Sendable {
    /// A ``Traversal`` focusing on **every** element of the collection.
    ///
    /// On contiguous collections (`Array`, `ContiguousArray`, `ArraySlice`) `forEach` and
    /// `modifyMut` go through the storage buffer, so no element is copied and no per-element
    /// accessor frame is allocated; other collections walk their indices. Either way `modifyMut`
    /// mutates each element in place — zero-copy on the buffer.
    ///
    /// ```swift
    /// [Int].each.getAll([10, 20, 30])          // [10, 20, 30]
    /// [Int].each.over { $0 * 2 }([10, 20, 30]) // [20, 40, 60]
    /// ```
    static var each: Traversal<Self, Element> {
        Traversal(
            getAll: { @Sendable in Array($0) },
            forEach: { @Sendable collection, body in
                // Contiguous storage (Array, ContiguousArray, ArraySlice) is read through its buffer
                // pointer: called from code that can't be specialised, `Collection`'s subscript and
                // iterator go through protocol witnesses whose accessor frames are heap-allocated,
                // which costs a malloc per element. The buffer subscript is a direct addressor.
                let visited: Void? = collection.withContiguousStorageIfAvailable { buffer in
                    for element in buffer {
                        body(element)
                    }
                }
                guard visited == nil else { return }
                for element in collection {
                    body(element)
                }
            },
            modifyMut: { @Sendable collection, f in
                // Same reason as `forEach`: write through the contiguous buffer when there is one.
                // The buffer is the collection's own (made unique first, as any write would), so
                // this is still in place.
                let mutated: Void? = collection.withContiguousMutableStorageIfAvailable { buffer in
                    for i in buffer.indices {
                        f(&buffer[i])
                    }
                }
                guard mutated == nil else { return }
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
    /// `modifyMut` mutates each value in place through `values`' own subscript, entered once for
    /// the whole loop: no per-value copy (a `[String: [Int]]` doesn't copy its arrays) and no
    /// re-hashing. Key order follows
    /// the dictionary's own iteration order.
    ///
    /// ```swift
    /// [String: Int].eachValue.over { $0 + 1 }(["a": 1, "b": 2])   // ["a": 2, "b": 3]
    /// ```
    static var eachValue: Traversal<[Key: Value], Value> {
        Traversal(
            getAll: { @Sendable in Array($0.values) },
            forEach: { @Sendable dict, body in
                for value in dict.values {
                    body(value)
                }
            },
            modifyMut: { @Sendable dict, f in
                modifyEachValue(&dict.values, f)
            }
        )
    }
}

/// Mutates every value through one `inout` access to `values`, rather than re-entering
/// `dict.values` for each one. `Dictionary.values`' modify accessor hands its storage over
/// without retaining it, so the values are still uniquely referenced and written in place.
private func modifyEachValue<Key, Value>(_ values: inout Dictionary<Key, Value>.Values, _ f: (inout Value) -> Void) {
    var i = values.startIndex
    while i != values.endIndex {
        f(&values[i])
        values.formIndex(after: &i)
    }
}

public extension MutableCollection where Index: Sendable, Element: Sendable {
    /// An ``IndexedTraversal`` focusing on every element, tagged with its collection index.
    ///
    /// `Array`, `ContiguousArray` and `ArraySlice` get the `Indices == Range<Int>` overload, which
    /// goes through their buffer. This one walks the indices, for every other collection and for
    /// generic code that only knows `MutableCollection`.
    ///
    /// ```swift
    /// [String].eachIndexed.getAll(["a", "b"])   // [(0, "a"), (1, "b")]
    /// ```
    static var eachIndexed: IndexedTraversal<Self, Index, Element> {
        IndexedTraversal(
            getAll: { @Sendable collection in collection.indices.map { ($0, collection[$0]) } },
            forEach: { @Sendable collection, body in
                for index in collection.indices {
                    body(index, collection[index])
                }
            },
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

public extension MutableCollection where Indices == Range<Int>, Element: Sendable {
    /// ``eachIndexed`` for collections indexed by a plain `Int` range (`Array`, `ContiguousArray`,
    /// `ArraySlice`). Their contiguous storage is read and written through its buffer, as ``each``
    /// does, and the index of the element at buffer offset `k` is `startIndex + k`.
    ///
    /// ```swift
    /// [String].eachIndexed.getAll(["a", "b"])   // [(0, "a"), (1, "b")]
    /// ```
    static var eachIndexed: IndexedTraversal<Self, Int, Element> {
        IndexedTraversal(
            forEach: { @Sendable collection, body in
                let start = collection.startIndex
                let visited: Void? = collection.withContiguousStorageIfAvailable { buffer in
                    for offset in buffer.indices {
                        body(start &+ offset, buffer[offset])
                    }
                }
                guard visited == nil else { return }
                for index in collection.indices {
                    body(index, collection[index])
                }
            },
            modifyMut: { @Sendable collection, f in
                let start = collection.startIndex
                let mutated: Void? = collection.withContiguousMutableStorageIfAvailable { buffer in
                    for offset in buffer.indices {
                        f(start &+ offset, &buffer[offset])
                    }
                }
                guard mutated == nil else { return }
                for index in collection.indices {
                    f(index, &collection[index])
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
            forEach: { @Sendable dict, body in
                for (key, value) in dict {
                    body(key, value)
                }
            },
            modifyMut: { @Sendable dict, f in
                var i = dict.values.startIndex
                while i != dict.values.endIndex {
                    f(dict.keys[i], &dict.values[i])
                    dict.values.formIndex(after: &i)
                }
            }
        )
    }
}
