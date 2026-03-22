import CoreFP

// DeferredTaskTEither: outer = DeferredTask, inner = Either
// Type: DeferredTask<Either<L, A>>

public func liftA2TDeferredTaskEither<L: Sendable, A: Sendable, B: Sendable, C: Sendable>(
    _ fn: @escaping @Sendable (A, B) -> C
) -> @Sendable (DeferredTask<Either<L, A>>, DeferredTask<Either<L, B>>) -> DeferredTask<Either<L, C>> {
    { @Sendable ta, tb in
        liftA2DeferredTask({ ea, eb -> Either<L, C> in
            switch (ea, eb) {
            case let (.right(a), .right(b)): .right(fn(a, b))
            case let (.left(l), _): .left(l)
            case let (_, .left(l)): .left(l)
            }
        })(ta, tb)
    }
}

public func applyTDeferredTaskEither<L: Sendable, A: Sendable, B: Sendable>(
    _ fns: DeferredTask<Either<L, @Sendable (A) -> B>>,
    _ values: DeferredTask<Either<L, A>>
) -> DeferredTask<Either<L, B>> {
    liftA2DeferredTask({ ef, ea -> Either<L, B> in
        switch (ef, ea) {
        case let (.right(f), .right(a)): .right(f(a))
        case let (.left(l), _): .left(l)
        case let (_, .left(l)): .left(l)
        }
    })(fns, values)
}
