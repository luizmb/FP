extension Dictionary: Semigroup {
    /// Combines two dictionaries, preferring values from the right side on key conflicts.
    public static func combine(_ lhs: [Key: Value], _ rhs: [Key: Value]) -> [Key: Value] {
        lhs.merging(rhs, uniquingKeysWith: withArg(\.1)(id))
    }
}

extension Dictionary: Monoid {
    public static var identity: [Key: Value] { [:] }
}
