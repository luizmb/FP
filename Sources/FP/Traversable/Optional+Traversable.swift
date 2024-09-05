/// Determine whether an optional String is nil or empty.
public extension Optional where Wrapped == String {
    var isNilOrEmpty: Bool {
        guard let wrapped = self else { return true }
        return wrapped.isEmpty
    }
}

/// Determine whether an optional String is nil or empty.
public extension Optional where Wrapped: Collection {
    var isNilOrEmpty: Bool {
        guard let wrapped = self else { return true }
        return wrapped.isEmpty
    }
}

public extension Optional where Wrapped: Collection {
    init(ifEmpty c: Wrapped) {
        self = c.isEmpty ? nil : .some(c)
    }
}
