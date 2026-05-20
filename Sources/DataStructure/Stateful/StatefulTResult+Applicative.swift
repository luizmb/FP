import CoreFP
import Foundation

// StatefulT + Result — free functions for Stateful<S, Result<A, E>>

/// apply for Stateful<S, Result>
public func applyStatefulResult<S, A, B, E: Error>(
    _ sf: Stateful<S, Result<(A) -> B, E>>,
    _ sa: Stateful<S, Result<A, E>>
) -> Stateful<S, Result<B, E>> {
    Stateful<S, Result<B, E>> { s in
        sf.run(&s).flatMap(sa.run(&s).map)
    }
}

/// liftA2 for Stateful<S, Result>
public func liftA2StatefulResult<S, A, B, C, E: Error>(
    _ fn: @escaping @Sendable (A, B) -> C
) -> (Stateful<S, Result<A, E>>, Stateful<S, Result<B, E>>) -> Stateful<S, Result<C, E>> {
    { sa, sb in
        Stateful<S, Result<C, E>> { s in
            Result.liftA2(fn)(sa.run(&s), sb.run(&s))
        }
    }
}

/// seqRight for Stateful<S, Result>
public func seqRightStatefulResult<S, A, B, E: Error>(
    _ lhs: Stateful<S, Result<A, E>>,
    _ rhs: Stateful<S, Result<B, E>>
) -> Stateful<S, Result<B, E>> {
    Stateful<S, Result<B, E>> { s in lhs.run(&s).seqRight(rhs.run(&s)) }
}

/// seqLeft for Stateful<S, Result>
public func seqLeftStatefulResult<S, A, B, E: Error>(
    _ lhs: Stateful<S, Result<A, E>>,
    _ rhs: Stateful<S, Result<B, E>>
) -> Stateful<S, Result<A, E>> {
    Stateful<S, Result<A, E>> { s in lhs.run(&s).seqLeft(rhs.run(&s)) }
}
