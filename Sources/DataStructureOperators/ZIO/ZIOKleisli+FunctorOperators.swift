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
