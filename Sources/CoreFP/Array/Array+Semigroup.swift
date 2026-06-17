extension Array: Semigroup {
    public static func combine(_ lhs: [Element], _ rhs: [Element]) -> [Element] {
        lhs + rhs
    }

    /// Single-pass fold into one accumulator — O(total count). The default left fold would
    /// rebuild a growing array on every `combine`, which is O(n²) for `Array`.
    public static func sconcat(_ first: [Element], _ rest: [[Element]]) -> [Element] {
        var result = first
        for next in rest { result.append(contentsOf: next) }
        return result
    }
}

extension Array: Monoid {
    public static var identity: [Element] { [] }

    /// Flatten in one pass — O(total count) — instead of the O(n²) left-folded concatenation.
    public static func mconcat(_ values: [[Element]]) -> [Element] {
        Array(values.joined())
    }
}
