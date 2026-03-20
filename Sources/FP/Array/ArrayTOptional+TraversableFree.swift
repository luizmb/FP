/// Sequence a list of optionals
/// sequence :: [a?] -> [a]?
public func sequence<A>(_ optionals: [A?]) -> [A]? {
    optionals.traverse(id)
}

/// Map and sequence
/// traverse :: (a -> b?) -> [a] -> [b]?
public func traverse<A, B>(_ fn: @escaping (A) -> B?) -> ([A]) -> [B]? {
    { array in
        array.traverse(fn)
    }
}
