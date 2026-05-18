extension Collection where Element: Identifiable {
    /// Returns the first element whose `id` equals `id`, or `nil` if none exists.
    ///
    /// This is the `Identifiable`-aware counterpart to ``Collection/subscript(safe:)``:
    /// it indexes by the element's stable identity rather than by position.
    ///
    /// ```swift
    /// struct User: Identifiable { let id: Int; let name: String }
    /// let users = [User(id: 1, name: "Alice"), User(id: 2, name: "Bob")]
    /// users[id: 1]   // Optional(User(id: 1, name: "Alice"))
    /// users[id: 9]   // nil
    /// ```
    ///
    /// Lookup is linear (`first(where:)`).
    ///
    /// - SeeAlso: ``RangeReplaceableCollection/subscript(id:)``
    public subscript(id id: Element.ID) -> Element? {
        first { $0.id == id }
    }
}

extension RangeReplaceableCollection where Element: Identifiable {
    /// Get-or-set an element by its `id`, with `Dictionary`-like add/remove semantics.
    ///
    /// Getter: returns the first element whose `id` equals `id`, or `nil`.
    ///
    /// Setter — chosen to mirror `Dictionary[key:]` over an `Identifiable` collection:
    ///
    /// | `newValue`         | element with matching `id` exists | behaviour              |
    /// |--------------------|:---:|------------------------|
    /// | `nil`              | yes | remove the element     |
    /// | `nil`              | no  | no-op                  |
    /// | `v` (`v.id == id`) | yes | replace in place       |
    /// | `v` (`v.id == id`) | no  | append to end          |
    /// | `v` (`v.id != id`) | —   | no-op (id mismatch)    |
    ///
    /// The id-mismatch no-op guards against accidental swaps — assigning an element
    /// whose `id` doesn't match the subscript key is almost always a bug.
    ///
    /// ```swift
    /// var users = [User(id: 1, name: "Alice"), User(id: 2, name: "Bob")]
    /// users[id: 2] = User(id: 2, name: "Robert")  // replace in place
    /// users[id: 3] = User(id: 3, name: "Carol")   // append to end
    /// users[id: 1] = nil                          // remove
    /// users[id: 9] = nil                          // no-op (not present)
    /// users[id: 2] = User(id: 99, name: "X")      // no-op (id mismatch)
    /// ```
    ///
    /// Lookup is linear (`firstIndex(where:)`).
    ///
    /// - SeeAlso: ``Collection/subscript(id:)``
    public subscript(id id: Element.ID) -> Element? {
        get { first { $0.id == id } }
        set {
            let existing = firstIndex { $0.id == id }
            switch (newValue, existing) {
            case let (value?, index?):
                guard value.id == id else { return }
                replaceSubrange(index..<self.index(after: index), with: CollectionOfOne(value))
            case let (value?, nil):
                guard value.id == id else { return }
                append(value)
            case let (nil, index?):
                remove(at: index)
            case (nil, nil):
                return
            }
        }
    }
}
