extension String: Semigroup {
    public static func combine(_ lhs: String, _ rhs: String) -> String {
        lhs + rhs
    }

    /// Single-pass fold into one accumulator — O(total length) — vs the default O(n²) left fold.
    public static func sconcat(_ first: String, _ rest: [String]) -> String {
        var result = first
        for next in rest { result.append(next) }
        return result
    }
}

extension String: Monoid {
    public static var identity: String { "" }

    /// Flatten in one pass — O(total length) — instead of O(n²) left-folded concatenation.
    public static func mconcat(_ values: [String]) -> String {
        values.joined()
    }
}
