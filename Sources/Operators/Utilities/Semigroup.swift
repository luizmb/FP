import FP

// MARK: - Semigroup (<>) - Associative concatenation

/// Semigroup concatenation for Arrays
/// (<>) :: [a] -> [a] -> [a]
public func <> <A>(_ lhs: [A], _ rhs: [A]) -> [A] {
    lhs + rhs
}

/// Semigroup concatenation for Strings
/// (<>) :: String -> String -> String
public func <> (_ lhs: String, _ rhs: String) -> String {
    lhs + rhs
}

/// Semigroup concatenation for dictionaries (merge, preferring right side for conflicts)
/// (<>) :: Dict k v -> Dict k v -> Dict k v
public func <> <K, V>(_ lhs: [K: V], _ rhs: [K: V]) -> [K: V] {
    lhs.merging(rhs, uniquingKeysWith: withArg(\.1)(id))
}

/// Semigroup concatenation for Sets
/// (<>) :: Set a -> Set a -> Set a
public func <> <A>(_ lhs: Set<A>, _ rhs: Set<A>) -> Set<A> {
    lhs.union(rhs)
}
