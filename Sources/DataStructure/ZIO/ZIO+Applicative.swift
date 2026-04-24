import CoreFP

// MARK: - Applicative

public extension ZIO {
    // pure :: a -> ZIO<env, a, e>
    // Lifts a pure value into ZIO, ignoring the environment.
    static func pure(_ value: Success) -> ZIO<Env, Success, Failure> {
        ZIO { _ in .pure(.success(value)) }
    }

    // seqRight :: ZIO<env, a, e> -> ZIO<env, b, e> -> ZIO<env, b, e>
    func seqRight<B: Sendable>(_ rhs: ZIO<Env, B, Failure>) -> ZIO<Env, B, Failure> {
        liftA2ZIO({ _, b in b })(self, rhs)
    }

    // seqLeft :: ZIO<env, a, e> -> ZIO<env, b, e> -> ZIO<env, a, e>
    func seqLeft<B: Sendable>(_ rhs: ZIO<Env, B, Failure>) -> ZIO<Env, Success, Failure> {
        liftA2ZIO({ a, _ in a })(self, rhs)
    }

    // zip :: ZIO<env, a, e> -> ZIO<env, b, e> -> ZIO<env, (a, b), e>
    // Call as ZIO<Env, (A, B), Failure>.zip(za, zb) — the where-clause ties Success to the tuple.
    static func zip<A: Sendable, B: Sendable>(
        _ first: ZIO<Env, A, Failure>,
        _ second: ZIO<Env, B, Failure>
    ) -> ZIO<Env, (A, B), Failure> where Success == (A, B) {
        liftA2ZIO({ ($0, $1) })(first, second)
    }
}

// applyZIO :: ZIO<env, (a -> b), e> -> ZIO<env, a, e> -> ZIO<env, b, e>
public func applyZIO<Env: Sendable, A: Sendable, B: Sendable, E: Error & Sendable>(
    _ fns: ZIO<Env, @Sendable (A) -> B, E>,
    _ values: ZIO<Env, A, E>
) -> ZIO<Env, B, E> {
    liftA2ZIO({ f, a in f(a) })(fns, values)
}

// liftA2ZIO :: (a -> b -> c) -> ZIO<env, a, e> -> ZIO<env, b, e> -> ZIO<env, c, e>
public func liftA2ZIO<Env: Sendable, A: Sendable, B: Sendable, C: Sendable, E: Error & Sendable>(
    _ fn: @escaping @Sendable (A, B) -> C
) -> @Sendable (ZIO<Env, A, E>, ZIO<Env, B, E>) -> ZIO<Env, C, E> {
    { @Sendable za, zb in
        ZIO<Env, C, E> { env in
            flatMapTDeferredTaskResult(za.run(env)) { a in
                mapTDeferredTaskResult({ b in fn(a, b) }, zb.run(env))
            }
        }
    }
}
