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

/// Semigroup concatenation for Optionals (using Alternative semantics)
/// (<>) :: Maybe a -> Maybe a -> Maybe a
public func <> <A>(_ lhs: A?, _ rhs: A?) -> A? {
    lhs ?? rhs
}

/// Semigroup concatenation for Results (first success or last failure)
/// (<>) :: Result a e -> Result a e -> Result a e
public func <> <A, E>(_ lhs: Result<A, E>, _ rhs: Result<A, E>) -> Result<A, E> {
    switch lhs {
    case .success: lhs
    case .failure: rhs
    }
}

/// Semigroup concatenation for dictionaries (merge, preferring right side for conflicts)
/// (<>) :: Dict k v -> Dict k v -> Dict k v
public func <> <K, V>(_ lhs: [K: V], _ rhs: [K: V]) -> [K: V] {
    lhs.merging(rhs, uniquingKeysWith: withArg(\.1)(identity))
}

/// Semigroup concatenation for Sets
/// (<>) :: Set a -> Set a -> Set a
public func <> <A>(_ lhs: Set<A>, _ rhs: Set<A>) -> Set<A> {
    lhs.union(rhs)
}

// MARK: - Function Semigroup

/// Semigroup concatenation for functions returning Semigroup types
/// For functions returning arrays
public func <> <A, B>(_ lhs: @escaping (A) -> [B], _ rhs: @escaping (A) -> [B]) -> (A) -> [B] {
    { a in lhs(a) <> rhs(a) }
}

/// For functions returning strings
public func <> <A>(_ lhs: @escaping (A) -> String, _ rhs: @escaping (A) -> String) -> (A) -> String {
    { a in lhs(a) <> rhs(a) }
}

/// For functions returning optionals
public func <> <A, B>(_ lhs: @escaping (A) -> B?, _ rhs: @escaping (A) -> B?) -> (A) -> B? {
    { a in lhs(a) <> rhs(a) }
}
