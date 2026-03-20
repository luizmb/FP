extension Set: Semigroup {
    public static func combine(_ lhs: Set<Element>, _ rhs: Set<Element>) -> Set<Element> {
        lhs.union(rhs)
    }
}

extension Set: Monoid {
    public static var identity: Set<Element> { [] }
}
