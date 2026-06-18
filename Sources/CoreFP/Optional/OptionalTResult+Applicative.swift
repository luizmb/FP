// SPDX-License-Identifier: Apache-2.0
import Foundation

// OptionalTResult: outer = Optional, inner = Result
// Type: Result<A,E>? = Optional<Result<A,E>>

/// apply for OptionalTResult: Result<(A->B),E>? -> Result<A,E>? -> Result<B,E>?
/// If outer is nil → nil; otherwise use Result.apply
public func applyOptionalResult<A, B, E: Error>(
    _ fns: Result<@Sendable (A) -> B, E>?,
    _ values: Result<A, E>?
) -> Result<B, E>? {
    fns.flatMap { rf in values.map { ra in Result.apply(rf, ra) } }
}

/// liftA2 for OptionalTResult: (A,B)->C -> Result<A,E>? -> Result<B,E>? -> Result<C,E>?
public func liftA2OptionalResult<A, B, C, E: Error>(
    _ fn: @escaping @Sendable (A, B) -> C
) -> (Result<A, E>?, Result<B, E>?) -> Result<C, E>? {
    Optional.liftA2({ @Sendable a, b in Result.liftA2(fn)(a, b) })
}

/// seqRight for OptionalTResult: Result<A,E>? -> Result<B,E>? -> Result<B,E>?
public func seqRightOptionalResult<A, B, E: Error>(_ lhs: Result<A, E>?, _ rhs: Result<B, E>?) -> Result<B, E>? {
    lhs.seqRight(rhs)
}

/// seqLeft for OptionalTResult: Result<A,E>? -> Result<B,E>? -> Result<A,E>?
public func seqLeftOptionalResult<A, B, E: Error>(_ lhs: Result<A, E>?, _ rhs: Result<B, E>?) -> Result<A, E>? {
    lhs.seqLeft(rhs)
}
