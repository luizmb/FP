import CoreFP
import Foundation

// StatefulTDeferredTask: outer = Stateful, inner = DeferredTask
// Type: Stateful<S, DeferredTask<A>>
//
// State is threaded synchronously; async execution happens later when the task runs.
// No `inout` crossing an async boundary.

/// apply for StatefulTDeferredTask
public func applyStatefulDeferredTask<S, A: Sendable, B: Sendable>(
    _ sf: Stateful<S, DeferredTask<@Sendable (A) -> B>>,
    _ sa: Stateful<S, DeferredTask<A>>
) -> Stateful<S, DeferredTask<B>> {
    Stateful<S, DeferredTask<B>> { s in
        let dtF = sf.run(&s)
        let dtA = sa.run(&s)
        return applyDeferredTask(dtF, dtA)
    }
}

/// liftA2 for StatefulTDeferredTask
public func liftA2StatefulDeferredTask<S, A: Sendable, B: Sendable, C: Sendable>(
    _ fn: @escaping @Sendable (A, B) -> C
) -> (Stateful<S, DeferredTask<A>>, Stateful<S, DeferredTask<B>>) -> Stateful<S, DeferredTask<C>> {
    { sa, sb in
        Stateful<S, DeferredTask<C>> { s in
            let dtA = sa.run(&s)
            let dtB = sb.run(&s)
            return liftA2DeferredTask(fn)(dtA, dtB)
        }
    }
}

/// seqRight for StatefulTDeferredTask
public func seqRightStatefulDeferredTask<S, A: Sendable, B: Sendable>(
    _ lhs: Stateful<S, DeferredTask<A>>,
    _ rhs: Stateful<S, DeferredTask<B>>
) -> Stateful<S, DeferredTask<B>> {
    Stateful<S, DeferredTask<B>> { s in lhs.run(&s).seqRight(rhs.run(&s)) }
}

/// seqLeft for StatefulTDeferredTask
public func seqLeftStatefulDeferredTask<S, A: Sendable, B: Sendable>(
    _ lhs: Stateful<S, DeferredTask<A>>,
    _ rhs: Stateful<S, DeferredTask<B>>
) -> Stateful<S, DeferredTask<A>> {
    Stateful<S, DeferredTask<A>> { s in lhs.run(&s).seqLeft(rhs.run(&s)) }
}
