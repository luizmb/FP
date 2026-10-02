// SPDX-License-Identifier: Apache-2.0
extension Set: Semigroup {
    public static func combine(_ lhs: Set<Element>, _ rhs: Set<Element>) -> Set<Element> {
        lhs.union(rhs)
    }

    /// Unions into one accumulator in place. The default left fold builds a new set per
    /// `union`, copying the growing accumulator every time.
    public static func sconcat(_ first: Set<Element>, _ rest: [Set<Element>]) -> Set<Element> {
        rest.reduce(into: first) { $0.formUnion($1) }
    }
}

extension Set: Monoid {
    public static var identity: Set<Element> { [] }
}
