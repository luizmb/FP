extension Collection {
    /// Returns the element at `index`, or `nil` if `index` is out of bounds.
    public subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

extension MutableCollection {
    /// Returns the element at `index`, or `nil` if `index` is out of bounds.
    /// Setting `nil` or setting at an out-of-bounds index is a no-op.
    public subscript(safe index: Index) -> Element? {
        get { indices.contains(index) ? self[index] : nil }
        set {
            guard let value = newValue, indices.contains(index) else { return }
            self[index] = value
        }
    }
}
