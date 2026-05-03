extension MutableCollection {
    /// Returns an `AffineTraversal` focusing on the element at `index`.
    /// Preview returns `nil` when `index` is out of bounds; set is a no-op in that case.
    ///
    /// ```swift
    /// [Int].ix(1).preview([10, 20, 30])        // Optional(20)
    /// [Int].ix(9).preview([10, 20, 30])        // nil
    /// [Int].ix(0).set([10, 20, 30], 99)        // [99, 20, 30]
    /// ```
    public static func ix(_ index: Index) -> AffineTraversal<Self, Element> {
        AffineTraversal(
            preview: { $0[safe: index] },
            set: { collection, element in
                var copy = collection
                copy[safe: index] = element
                return copy
            }
        )
    }
}

extension MutableCollection where Element: Identifiable {
    /// Returns an `AffineTraversal` focusing on the first element whose `id` matches.
    /// Preview returns `nil` when no element with that `id` exists; set is a no-op in that case.
    ///
    /// ```swift
    /// [Item].ix(id: 2).preview(items)?.name   // "B"
    /// [Item].ix(id: 99).preview(items)        // nil
    /// ```
    public static func ix(id: Element.ID) -> AffineTraversal<Self, Element> {
        AffineTraversal(
            preview: { $0.first(where: { $0.id == id }) },
            set: { collection, element in
                guard let idx = collection.firstIndex(where: { $0.id == id }) else { return collection }
                var copy = collection
                copy[idx] = element
                return copy
            }
        )
    }
}

extension Dictionary {
    /// Returns an `AffineTraversal` focusing on the value for `key`.
    /// Preview returns `nil` when the key is absent; set is a no-op in that case.
    ///
    /// ```swift
    /// [String: Int].ix(key: "a").preview(["a": 1, "b": 2])   // Optional(1)
    /// [String: Int].ix(key: "z").preview(["a": 1, "b": 2])   // nil
    /// [String: Int].ix(key: "a").set(["a": 1, "b": 2], 99)   // ["a": 99, "b": 2]
    /// ```
    public static func ix(key: Key) -> AffineTraversal<[Key: Value], Value> {
        AffineTraversal(
            preview: { $0[key] },
            set: { dict, value in
                guard dict[key] != nil else { return dict }
                var copy = dict
                copy[key] = value
                return copy
            }
        )
    }
}
