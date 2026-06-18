// SPDX-License-Identifier: Apache-2.0
import Foundation

// ArrayTResult: outer = Array, inner = Result
// Type: [Result<A,E>] = Array<Result<A,E>>

/// apply for ArrayTResult: [Result<(A->B),E>] -> [Result<A,E>] -> [Result<B,E>]
/// Cartesian product with Result apply at each pair
public func applyArrayResult<A, B, E: Error>(
    _ fns: [Result<@Sendable (A) -> B, E>],
    _ values: [Result<A, E>]
) -> [Result<B, E>] {
    Array.liftA2(Result.apply)(fns, values)
}

/// liftA2 for ArrayTResult: (A,B)->C -> [Result<A,E>] -> [Result<B,E>] -> [Result<C,E>]
public func liftA2ArrayResult<A, B, C, E: Error>(
    _ fn: @escaping @Sendable (A, B) -> C
) -> ([Result<A, E>], [Result<B, E>]) -> [Result<C, E>] {
    { arrA, arrB in
        Array.liftA2({ @Sendable a, b in Result.liftA2(fn)(a, b) })(arrA, arrB)
    }
}

/// seqRight for ArrayTResult: [Result<A,E>] -> [Result<B,E>] -> [Result<B,E>]
public func seqRightArrayResult<A, B, E: Error>(
    _ lhs: [Result<A, E>],
    _ rhs: [Result<B, E>]
) -> [Result<B, E>] {
    Array.liftA2({ (a: Result<A, E>, b: Result<B, E>) in a.seqRight(b) })(lhs, rhs)
}

/// seqLeft for ArrayTResult: [Result<A,E>] -> [Result<B,E>] -> [Result<A,E>]
public func seqLeftArrayResult<A, B, E: Error>(
    _ lhs: [Result<A, E>],
    _ rhs: [Result<B, E>]
) -> [Result<A, E>] {
    Array.liftA2({ (a: Result<A, E>, b: Result<B, E>) in a.seqLeft(b) })(lhs, rhs)
}
