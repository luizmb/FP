// SPDX-License-Identifier: Apache-2.0
import CoreFP

// ArrayTOptional: outer = Array, inner = Optional
// Type: [A?] = Array<Optional<A>>

/// (<*>) :: [(a -> b)?] -> [a?] -> [b?]
public func <*> <A, B>(_ fns: [(@Sendable (A) -> B)?], _ values: [A?]) -> [B?] where A: Sendable {
    applyArrayOptional(fns, values)
}

/// (*>) :: [a?] -> [b?] -> [b?]
public func *> <A, B>(_ lhs: [A?], _ rhs: [B?]) -> [B?] where B: Sendable {
    seqRightArrayOptional(lhs, rhs)
}

/// (<*) :: [a?] -> [b?] -> [a?]
public func <* <A, B>(_ lhs: [A?], _ rhs: [B?]) -> [A?] where A: Sendable, B: Sendable {
    seqLeftArrayOptional(lhs, rhs)
}
