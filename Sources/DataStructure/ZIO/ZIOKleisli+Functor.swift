import CoreFP

// MARK: - Functor

public extension ZIOKleisli {
    // map :: (a -> b) -> ZIOKleisli<i, env, a, e> -> ZIOKleisli<i, env, b, e>
    func map<B: Sendable>(_ fn: @escaping @Sendable (Success) -> B) -> ZIOKleisli<Input, Env, B, Failure> {
        ZIOKleisli<Input, Env, B, Failure> { input in run(input).map(fn) }
    }

    // fmap :: (a -> b) -> ZIOKleisli<i, env, a, e> -> ZIOKleisli<i, env, b, e>
    static func fmap<B: Sendable>(
        _ fn: @escaping @Sendable (Success) -> B
    ) -> @Sendable (ZIOKleisli<Input, Env, Success, Failure>) -> ZIOKleisli<Input, Env, B, Failure> {
        { @Sendable k in k.map(fn) }
    }

    func replace<B: Sendable>(_ value: B) -> ZIOKleisli<Input, Env, B, Failure> {
        map(const(value))
    }

    // mapError :: (e -> e2) -> ZIOKleisli<i, env, a, e> -> ZIOKleisli<i, env, a, e2>
    func mapError<F2: Error & Sendable>(
        _ fn: @escaping @Sendable (Failure) -> F2
    ) -> ZIOKleisli<Input, Env, Success, F2> {
        ZIOKleisli<Input, Env, Success, F2> { input in run(input).mapError(fn) }
    }
}

// mapZIOKleisli :: (a -> b) -> ZIOKleisli<i, env, a, e> -> ZIOKleisli<i, env, b, e>
public func mapZIOKleisli<I: Sendable, Env: Sendable, A: Sendable, B: Sendable, E: Error & Sendable>(
    _ fn: @escaping @Sendable (A) -> B,
    _ k: ZIOKleisli<I, Env, A, E>
) -> ZIOKleisli<I, Env, B, E> {
    k.map(fn)
}

// fmapZIOKleisli :: (a -> b) -> ZIOKleisli<i, env, a, e> -> ZIOKleisli<i, env, b, e>
public func fmapZIOKleisli<I: Sendable, Env: Sendable, A: Sendable, B: Sendable, E: Error & Sendable>(
    _ fn: @escaping @Sendable (A) -> B
) -> @Sendable (ZIOKleisli<I, Env, A, E>) -> ZIOKleisli<I, Env, B, E> {
    { @Sendable k in k.map(fn) }
}
