extension String: Semigroup {
    public static func combine(_ lhs: String, _ rhs: String) -> String {
        lhs + rhs
    }

    /// Routes through the stdlib `joined()`, which pre-sizes over the contiguous UTF-8 — vs the
    /// default left fold, which reallocates a growing `String` on every `combine` (O(n²)).
    public static func sconcat(_ first: String, _ rest: [String]) -> String {
        rest.isEmpty ? first : ([first] + rest).joined()
    }
}

extension String: Monoid {
    public static var identity: String { "" }

    /// Pre-sized flatten via the stdlib `joined()` — instead of an O(n²) left-folded concat.
    public static func mconcat(_ values: [String]) -> String {
        values.joined()
    }
}
