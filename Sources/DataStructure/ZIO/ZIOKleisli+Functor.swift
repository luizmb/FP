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

    /// Contramap on the input - transforms the input before passing it to the ZIOKleisli.
    /// contramap :: (i2 -> i) -> ZIOKleisli<i, env, a, e> -> ZIOKleisli<i2, env, a, e>
    func contramap<Input2: Sendable>(
        _ fn: @escaping @Sendable (Input2) -> Input
    ) -> ZIOKleisli<Input2, Env, Success, Failure> {
        ZIOKleisli<Input2, Env, Success, Failure> { input2 in
            run(fn(input2))
        }
    }

    /// Curried contramap for functional composition.
    static func contramap<Input2: Sendable>(
        _ fn: @escaping @Sendable (Input2) -> Input
    ) -> (ZIOKleisli<Input, Env, Success, Failure>) -> ZIOKleisli<Input2, Env, Success, Failure> {
        { $0.contramap(fn) }
    }

    /// Contramap on the environment - transforms the environment before passing it to the ZIO.
    /// contramapEnvironment :: (r2 -> r) -> ZIOKleisli<i, r, a, e> -> ZIOKleisli<i, r2, a, e>
    func contramapEnvironment<GlobalEnv: Sendable>(
        _ fn: @escaping @Sendable (GlobalEnv) -> Env
    ) -> ZIOKleisli<Input, GlobalEnv, Success, Failure> {
        ZIOKleisli<Input, GlobalEnv, Success, Failure> { input in
            run(input).contramapEnvironment(fn)
        }
    }

    /// Curried contramapEnvironment for functional composition.
    static func contramapEnvironment<GlobalEnv: Sendable>(
        _ fn: @escaping @Sendable (GlobalEnv) -> Env
    ) -> (ZIOKleisli<Input, Env, Success, Failure>) -> ZIOKleisli<Input, GlobalEnv, Success, Failure> {
        { $0.contramapEnvironment(fn) }
    }

    /// Dimap combines contramap (input), contramapEnvironment (env), and map (output).
    /// dimap :: (i2 -> i) -> (r2 -> r) -> (a -> b) -> ZIOKleisli<i, r, a, e> -> ZIOKleisli<i2, r2, b, e>
    func dimap<Input2: Sendable, GlobalEnv: Sendable, B: Sendable>(
        _ contramapInput: @escaping @Sendable (Input2) -> Input,
        _ contramapEnv: @escaping @Sendable (GlobalEnv) -> Env,
        _ mapOutput: @escaping @Sendable (Success) -> B
    ) -> ZIOKleisli<Input2, GlobalEnv, B, Failure> {
        ZIOKleisli<Input2, GlobalEnv, B, Failure> { input2 in
            run(contramapInput(input2)).dimap(contramapEnv, mapOutput)
        }
    }

    /// Curried dimap for functional composition.
    static func dimap<Input2: Sendable, GlobalEnv: Sendable, B: Sendable>(
        _ contramapInput: @escaping @Sendable (Input2) -> Input,
        _ contramapEnv: @escaping @Sendable (GlobalEnv) -> Env,
        _ mapOutput: @escaping @Sendable (Success) -> B
    ) -> (ZIOKleisli<Input, Env, Success, Failure>) -> ZIOKleisli<Input2, GlobalEnv, B, Failure> {
        { $0.dimap(contramapInput, contramapEnv, mapOutput) }
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

// contramapZIOKleisli :: (i2 -> i) -> ZIOKleisli<i, env, a, e> -> ZIOKleisli<i2, env, a, e>
public func contramapZIOKleisli<I2: Sendable, I: Sendable, Env: Sendable, A: Sendable, E: Error & Sendable>(
    _ fn: @escaping @Sendable (I2) -> I,
    _ k: ZIOKleisli<I, Env, A, E>
) -> ZIOKleisli<I2, Env, A, E> {
    k.contramap(fn)
}

// contramapEnvironmentZIOKleisli :: (r2 -> r) -> ZIOKleisli<i, r, a, e> -> ZIOKleisli<i, r2, a, e>
public func contramapEnvironmentZIOKleisli<I: Sendable, GlobalEnv: Sendable, Env: Sendable, A: Sendable, E: Error & Sendable>(
    _ fn: @escaping @Sendable (GlobalEnv) -> Env,
    _ k: ZIOKleisli<I, Env, A, E>
) -> ZIOKleisli<I, GlobalEnv, A, E> {
    k.contramapEnvironment(fn)
}

// dimapZIOKleisli :: (i2 -> i) -> (r2 -> r) -> (a -> b) -> ZIOKleisli<i, r, a, e> -> ZIOKleisli<i2, r2, b, e>
public func dimapZIOKleisli<I2: Sendable, I: Sendable, GlobalEnv: Sendable, Env: Sendable, A: Sendable, B: Sendable, E: Error & Sendable>(
    _ contramapInput: @escaping @Sendable (I2) -> I,
    _ contramapEnv: @escaping @Sendable (GlobalEnv) -> Env,
    _ mapOutput: @escaping @Sendable (A) -> B,
    _ k: ZIOKleisli<I, Env, A, E>
) -> ZIOKleisli<I2, GlobalEnv, B, E> {
    k.dimap(contramapInput, contramapEnv, mapOutput)
}
