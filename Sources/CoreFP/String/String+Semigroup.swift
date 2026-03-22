extension String: Semigroup {
    public static func combine(_ lhs: String, _ rhs: String) -> String {
        lhs + rhs
    }
}

extension String: Monoid {
    public static var identity: String { "" }
}
