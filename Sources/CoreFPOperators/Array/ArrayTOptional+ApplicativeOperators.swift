import CoreFP

// ArrayTOptional: outer = Array, inner = Optional
// Type: [A?] = Array<Optional<A>>

// (<*>) :: [(a -> b)?] -> [a?] -> [b?]
public func <*> <A, B>(_ fns: [((A) -> B)?], _ values: [A?]) -> [B?] {
    applyArrayOptional(fns, values)
}

// (*>) :: [a?] -> [b?] -> [b?]
public func *> <A, B>(_ lhs: [A?], _ rhs: [B?]) -> [B?] {
    seqRightArrayOptional(lhs, rhs)
}

// (<*) :: [a?] -> [b?] -> [a?]
public func <* <A, B>(_ lhs: [A?], _ rhs: [B?]) -> [A?] {
    seqLeftArrayOptional(lhs, rhs)
}
