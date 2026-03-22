import Core

// OptionalTArray: outer = Optional, inner = Array
// Type: [A]? = Optional<[A]>

// (<*>) :: [(a -> b)]? -> [a]? -> [b]?
public func <*> <A, B>(_ fns: [(A) -> B]?, _ values: [A]?) -> [B]? {
    applyOptionalArray(fns, values)
}

// (*>) :: [a]? -> [b]? -> [b]?
public func *> <A, B>(_ lhs: [A]?, _ rhs: [B]?) -> [B]? {
    seqRightOptionalArray(lhs, rhs)
}

// (<*) :: [a]? -> [b]? -> [a]?
public func <* <A, B>(_ lhs: [A]?, _ rhs: [B]?) -> [A]? {
    seqLeftOptionalArray(lhs, rhs)
}
