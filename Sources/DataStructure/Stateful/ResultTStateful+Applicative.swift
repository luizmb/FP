// SPDX-License-Identifier: Apache-2.0
import Foundation

// ResultTStateful: outer = Result, inner = Stateful
// Type: Result<Stateful<S, A>, E>

/// apply for ResultTStateful: Result<Stateful<S,(A->B)>,E> -> Result<Stateful<S,A>,E> -> Result<Stateful<S,B>,E>
public func applyResultStateful<S, A, B, E: Error>(
    _ rf: Result<Stateful<S, @Sendable (A) -> B>, E>,
    _ ra: Result<Stateful<S, A>, E>
) -> Result<Stateful<S, B>, E> {
    rf.flatMap { sf in ra.map { sa in Stateful<S, B>.apply(sf, sa) } }
}

/// liftA2 for ResultTStateful
public func liftA2ResultStateful<S, A, B, C, E: Error>(
    _ fn: @escaping @Sendable (A, B) -> C
) -> (Result<Stateful<S, A>, E>, Result<Stateful<S, B>, E>) -> Result<Stateful<S, C>, E> {
    { ra, rb in
        ra.flatMap { sa in rb.map { sb in Stateful<S, C> { s in fn(sa.run(&s), sb.run(&s)) } } }
    }
}

/// seqRight for ResultTStateful
public func seqRightResultStateful<S, A, B, E: Error>(
    _ lhs: Result<Stateful<S, A>, E>,
    _ rhs: Result<Stateful<S, B>, E>
) -> Result<Stateful<S, B>, E> {
    lhs.flatMap { sa in rhs.map { sb in sa.seqRight(sb) } }
}

/// seqLeft for ResultTStateful
public func seqLeftResultStateful<S, A, B, E: Error>(
    _ lhs: Result<Stateful<S, A>, E>,
    _ rhs: Result<Stateful<S, B>, E>
) -> Result<Stateful<S, A>, E> {
    lhs.flatMap { sa in rhs.map { sb in sa.seqLeft(sb) } }
}
