extension Array: Semigroup {
    public static func combine(_ lhs: [Element], _ rhs: [Element]) -> [Element] {
        lhs + rhs
    }
}

extension Array: Monoid {
    public static var identity: [Element] { [] }
}
