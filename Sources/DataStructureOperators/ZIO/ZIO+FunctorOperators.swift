import CoreFP
import CoreFPOperators
import DataStructure

// (<£>) :: (a -> b) -> ZIO<env, a, e> -> ZIO<env, b, e>
public func <£> <Env: Sendable, A: Sendable, B: Sendable, E: Error & Sendable>(
    _ fn: @escaping @Sendable (A) -> B,
    _ zio: ZIO<Env, A, E>
) -> ZIO<Env, B, E> {
    zio.map(fn)
}

// (<&>) :: ZIO<env, a, e> -> (a -> b) -> ZIO<env, b, e>
public func <&> <Env: Sendable, A: Sendable, B: Sendable, E: Error & Sendable>(
    _ zio: ZIO<Env, A, E>,
    _ fn: @escaping @Sendable (A) -> B
) -> ZIO<Env, B, E> {
    zio.map(fn)
}

// (£>) :: ZIO<env, a, e> -> b -> ZIO<env, b, e>
public func £> <Env: Sendable, A: Sendable, B: Sendable, E: Error & Sendable>(
    _ zio: ZIO<Env, A, E>,
    _ value: B
) -> ZIO<Env, B, E> {
    zio.replace(value)
}

// (<£) :: b -> ZIO<env, a, e> -> ZIO<env, b, e>
public func <£ <Env: Sendable, A: Sendable, B: Sendable, E: Error & Sendable>(
    _ value: B,
    _ zio: ZIO<Env, A, E>
) -> ZIO<Env, B, E> {
    zio £> value
}

// contramapEnvironment: (r2 -> r) -> ZIO<r, a, e> -> ZIO<r2, a, e>
// Uses >>> for composition: first transform env, then run ZIO
public func >>> <GlobalEnv: Sendable, Env: Sendable, A: Sendable, E: Error & Sendable>(
    _ contramapEnv: @escaping @Sendable (GlobalEnv) -> Env,
    _ zio: ZIO<Env, A, E>
) -> ZIO<GlobalEnv, A, E> {
    zio.contramapEnvironment(contramapEnv)
}
