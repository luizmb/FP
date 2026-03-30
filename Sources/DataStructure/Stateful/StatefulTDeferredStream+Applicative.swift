import CoreFP
import Foundation

// StatefulTDeferredStream: outer = Stateful, inner = DeferredStream
// Type: Stateful<S, DeferredStream<A>>
//
// State is threaded synchronously; streaming happens later when iterated.

/// apply for StatefulTDeferredStream
public func applyStatefulDeferredStream<S, A: Sendable, B: Sendable>(
    _ sf: Stateful<S, DeferredStream<@Sendable (A) -> B>>,
    _ sa: Stateful<S, DeferredStream<A>>
) -> Stateful<S, DeferredStream<B>> {
    Stateful<S, DeferredStream<B>> { s in
        let dsF = sf.run(&s)
        let dsA = sa.run(&s)
        return applyDeferredStream(dsF, dsA)
    }
}

/// liftA2 for StatefulTDeferredStream
public func liftA2StatefulDeferredStream<S, A: Sendable, B: Sendable, C: Sendable>(
    _ fn: @escaping @Sendable (A, B) -> C
) -> (Stateful<S, DeferredStream<A>>, Stateful<S, DeferredStream<B>>) -> Stateful<S, DeferredStream<C>> {
    { sa, sb in
        Stateful<S, DeferredStream<C>> { s in
            let dsA = sa.run(&s)
            let dsB = sb.run(&s)
            return liftA2DeferredStream(fn)(dsA, dsB)
        }
    }
}

/// seqRight for StatefulTDeferredStream
public func seqRightStatefulDeferredStream<S, A: Sendable, B: Sendable>(
    _ lhs: Stateful<S, DeferredStream<A>>,
    _ rhs: Stateful<S, DeferredStream<B>>
) -> Stateful<S, DeferredStream<B>> {
    Stateful<S, DeferredStream<B>> { s in lhs.run(&s).seqRight(rhs.run(&s)) }
}

/// seqLeft for StatefulTDeferredStream
public func seqLeftStatefulDeferredStream<S, A: Sendable, B: Sendable>(
    _ lhs: Stateful<S, DeferredStream<A>>,
    _ rhs: Stateful<S, DeferredStream<B>>
) -> Stateful<S, DeferredStream<A>> {
    Stateful<S, DeferredStream<A>> { s in lhs.run(&s).seqLeft(rhs.run(&s)) }
}
