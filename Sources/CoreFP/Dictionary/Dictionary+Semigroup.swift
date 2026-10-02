// SPDX-License-Identifier: Apache-2.0
extension Dictionary: Semigroup {
    /// Combines two dictionaries, preferring values from the right side on key conflicts.
    public static func combine(_ lhs: [Key: Value], _ rhs: [Key: Value]) -> [Key: Value] {
        lhs.merging(rhs, uniquingKeysWith: withArg(\.1)(id))
    }

    /// Merges into one accumulator in place (right-biased, like ``combine(_:_:)``). The
    /// default left fold builds a new dictionary per `merging`, copying the accumulator.
    public static func sconcat(_ first: [Key: Value], _ rest: [[Key: Value]]) -> [Key: Value] {
        rest.reduce(into: first) { $0.merge($1, uniquingKeysWith: withArg(\.1)(id)) }
    }
}

extension Dictionary: Monoid {
    public static var identity: [Key: Value] { [:] }
}
