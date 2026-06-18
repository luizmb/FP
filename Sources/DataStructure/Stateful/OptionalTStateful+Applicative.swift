// SPDX-License-Identifier: Apache-2.0
import Foundation

// OptionalTStateful: outer = Optional, inner = Stateful
// Type: Stateful<S, A>? = Optional<Stateful<S, A>>

/// apply for OptionalTStateful: Stateful<S,(A->B)>? -> Stateful<S,A>? -> Stateful<S,B>?
public func applyOptionalStateful<S, A, B>(
    _ sf: Stateful<S, @Sendable (A) -> B>?,
    _ sa: Stateful<S, A>?
) -> Stateful<S, B>? {
    sf.flatMap { f in sa.map { a in Stateful<S, B>.apply(f, a) } }
}

/// liftA2 for OptionalTStateful
public func liftA2OptionalStateful<S, A, B, C>(
    _ fn: @escaping @Sendable (A, B) -> C
) -> (Stateful<S, A>?, Stateful<S, B>?) -> Stateful<S, C>? {
    { sa, sb in
        sa.flatMap { a in sb.map { b in Stateful<S, C> { s in fn(a.run(&s), b.run(&s)) } } }
    }
}

/// seqRight for OptionalTStateful
public func seqRightOptionalStateful<S, A, B>(
    _ lhs: Stateful<S, A>?,
    _ rhs: Stateful<S, B>?
) -> Stateful<S, B>? {
    lhs.flatMap { sa in rhs.map { sb in sa.seqRight(sb) } }
}

/// seqLeft for OptionalTStateful
public func seqLeftOptionalStateful<S, A, B>(
    _ lhs: Stateful<S, A>?,
    _ rhs: Stateful<S, B>?
) -> Stateful<S, A>? {
    lhs.flatMap { sa in rhs.map { sb in sa.seqLeft(sb) } }
}
