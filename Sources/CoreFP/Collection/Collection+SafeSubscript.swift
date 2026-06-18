// SPDX-License-Identifier: Apache-2.0
extension Collection {
    /// Returns the element at `index`, or `nil` if `index` is out of bounds.
    ///
    /// This is the safe alternative to the standard `[index]` subscript, which
    /// traps on out-of-bounds access. Use this when `index` might be beyond the
    /// valid range, for example when computing an index from external data.
    ///
    /// ```swift
    /// let xs = [10, 20, 30]
    /// xs[safe: 1]   // Optional(20)
    /// xs[safe: 9]   // nil
    /// ```
    ///
    /// - SeeAlso: ``MutableCollection/subscript(safe:)``
    public subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

extension MutableCollection {
    /// Returns the element at `index`, or `nil` if `index` is out of bounds.
    /// Setting `nil` or setting at an out-of-bounds index is a no-op.
    ///
    /// The setter is guarded: it does nothing when `newValue` is `nil` or `index`
    /// is out of bounds. This makes the subscript safe to use in update pipelines
    /// where the index may have become invalid.
    ///
    /// ```swift
    /// var xs = [10, 20, 30]
    /// xs[safe: 1] = 99   // xs == [10, 99, 30]
    /// xs[safe: 9] = 99   // no-op
    /// xs[safe: 0] = nil  // no-op
    /// ```
    ///
    /// Used internally by the ``ix(_:)`` affine traversal.
    public subscript(safe index: Index) -> Element? {
        get { indices.contains(index) ? self[index] : nil }
        set {
            guard let value = newValue, indices.contains(index) else { return }
            self[index] = value
        }
    }
}
