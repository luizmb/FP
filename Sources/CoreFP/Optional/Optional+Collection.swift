// SPDX-License-Identifier: Apache-2.0
public extension Optional where Wrapped: Collection {
    /// Returns true if the Optional is nil or contains an empty Collection.
    var isNilOrEmpty: Bool {
        guard let wrapped = self else { return true }
        return wrapped.isEmpty
    }

    /// Wraps a Collection in an Optional, returning nil if it is empty.
    init(ifEmpty c: Wrapped) {
        self = c.isEmpty ? nil : .some(c)
    }
}
