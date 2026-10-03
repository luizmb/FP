// SPDX-License-Identifier: Apache-2.0
import CoreFP

// ArrayTResult: outer = Array, inner = Result
// Type: [Result<A,E>] = Array<Result<A,E>>

/// (<*>) :: [Result<(a -> b), e>] -> [Result<a, e>] -> [Result<b, e>]
public func <*> <A, B, E: Error>(_ fns: [Result<@Sendable (A) -> B, E>], _ values: [Result<A, E>]) -> [Result<B, E>] where A: Sendable {
    applyArrayResult(fns, values)
}

/// (*>) :: [Result<a,e>] -> [Result<b,e>] -> [Result<b,e>]
public func *> <A, B, E: Error>(_ lhs: [Result<A, E>], _ rhs: [Result<B, E>]) -> [Result<B, E>] where B: Sendable {
    seqRightArrayResult(lhs, rhs)
}

/// (<*) :: [Result<a,e>] -> [Result<b,e>] -> [Result<a,e>]
public func <* <A, B, E: Error>(_ lhs: [Result<A, E>], _ rhs: [Result<B, E>]) -> [Result<A, E>] where A: Sendable, B: Sendable {
    seqLeftArrayResult(lhs, rhs)
}
