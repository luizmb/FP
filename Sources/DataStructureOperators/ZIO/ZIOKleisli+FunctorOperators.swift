import CoreFP
import CoreFPOperators
import DataStructure

// (<£>) :: (a -> b) -> ZIOKleisli<i, env, a, e> -> ZIOKleisli<i, env, b, e>
public func <£> <I: Sendable, Env: Sendable, A: Sendable, B: Sendable, E: Error & Sendable>(
    _ fn: @escaping @Sendable (A) -> B,
    _ k: ZIOKleisli<I, Env, A, E>
) -> ZIOKleisli<I, Env, B, E> {
    k.map(fn)
}

// (<&>) :: ZIOKleisli<i, env, a, e> -> (a -> b) -> ZIOKleisli<i, env, b, e>
public func <&> <I: Sendable, Env: Sendable, A: Sendable, B: Sendable, E: Error & Sendable>(
    _ k: ZIOKleisli<I, Env, A, E>,
    _ fn: @escaping @Sendable (A) -> B
) -> ZIOKleisli<I, Env, B, E> {
    k.map(fn)
}

// (£>) :: ZIOKleisli<i, env, a, e> -> b -> ZIOKleisli<i, env, b, e>
public func £> <I: Sendable, Env: Sendable, A: Sendable, B: Sendable, E: Error & Sendable>(
    _ k: ZIOKleisli<I, Env, A, E>,
    _ value: B
) -> ZIOKleisli<I, Env, B, E> {
    k.replace(value)
}

// (<£) :: b -> ZIOKleisli<i, env, a, e> -> ZIOKleisli<i, env, b, e>
public func <£ <I: Sendable, Env: Sendable, A: Sendable, B: Sendable, E: Error & Sendable>(
    _ value: B,
    _ k: ZIOKleisli<I, Env, A, E>
) -> ZIOKleisli<I, Env, B, E> {
    k £> value
}

// contramap: (i2 -> i) -> ZIOKleisli<i, env, a, e> -> ZIOKleisli<i2, env, a, e>
// Uses >>> for composition: first transform input, then run ZIOKleisli
public func >>> <I2: Sendable, I: Sendable, Env: Sendable, A: Sendable, E: Error & Sendable>(
    _ contramapInput: @escaping @Sendable (I2) -> I,
    _ k: ZIOKleisli<I, Env, A, E>
) -> ZIOKleisli<I2, Env, A, E> {
    k.contramap(contramapInput)
}

// contramapEnvironment: (r2 -> r) -> ZIOKleisli<i, r, a, e> -> ZIOKleisli<i, r2, a, e>
public func >>> <I: Sendable, GlobalEnv: Sendable, Env: Sendable, A: Sendable, E: Error & Sendable>(
    _ contramapEnv: @escaping @Sendable (GlobalEnv) -> Env,
    _ k: ZIOKleisli<I, Env, A, E>
) -> ZIOKleisli<I, GlobalEnv, A, E> {
    k.contramapEnvironment(contramapEnv)
}
