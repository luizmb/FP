// SPDX-License-Identifier: Apache-2.0
extension Array: Semigroup {
    public static func combine(_ lhs: [Element], _ rhs: [Element]) -> [Element] {
        lhs + rhs
    }

    /// Pre-sized single-pass fold — one allocation, each element copied once. The default left
    /// fold would rebuild a growing array on every `combine` (O(n²) for `Array`); even a plain
    /// append loop reallocates as it grows. Summing `count` is O(1) per sub-array.
    public static func sconcat(_ first: [Element], _ rest: [[Element]]) -> [Element] {
        var result = first
        result.reserveCapacity(rest.reduce(into: first.count) { $0 += $1.count })
        for next in rest { result.append(contentsOf: next) }
        return result
    }
}

extension Array: Monoid {
    public static var identity: [Element] { [] }

    /// Pre-sized flatten — one allocation, each element copied once — vs the O(n²) left fold.
    public static func mconcat(_ values: [[Element]]) -> [Element] {
        var result = [Element]()
        result.reserveCapacity(values.reduce(into: 0) { $0 += $1.count })
        for next in values { result.append(contentsOf: next) }
        return result
    }
}
