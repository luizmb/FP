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

// contramapEnvironment: (GlobalEnv -> Env) -> ZIO<Env, a, e> -> ZIO<GlobalEnv, a, e>
//
// The `>>>` operator is reused here in its contravariant sense:
//   `envNarrow >>> zio` reads as "first narrow the environment, then run zio".
// This is the ZIO equivalent of Reader's contramapEnvironment — it widens a ZIO
// that requires a specific environment into one that accepts a broader environment.
//
// Example:
//   let narrow: ZIO<UserService, User, DBError> = ...
//   let wide: ZIO<AppEnv, User, DBError> = \.userService >>> narrow
public func >>> <GlobalEnv: Sendable, Env: Sendable, A: Sendable, E: Error & Sendable>(
    _ contramapEnv: @escaping @Sendable (GlobalEnv) -> Env,
    _ zio: ZIO<Env, A, E>
) -> ZIO<GlobalEnv, A, E> {
    zio.contramapEnvironment(contramapEnv)
}
