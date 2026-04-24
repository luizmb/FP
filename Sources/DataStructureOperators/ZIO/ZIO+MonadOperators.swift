import CoreFP
import CoreFPOperators
import DataStructure

// (>>-) :: ZIO<env, a, e> -> (a -> ZIO<env, b, e>) -> ZIO<env, b, e>
public func >>- <Env: Sendable, A: Sendable, B: Sendable, E: Error & Sendable>(
    _ zio: ZIO<Env, A, E>,
    _ fn: @escaping @Sendable (A) -> ZIO<Env, B, E>
) -> ZIO<Env, B, E> {
    zio.flatMap(fn)
}

// (-<<) :: (a -> ZIO<env, b, e>) -> ZIO<env, a, e> -> ZIO<env, b, e>
public func -<< <Env: Sendable, A: Sendable, B: Sendable, E: Error & Sendable>(
    _ fn: @escaping @Sendable (A) -> ZIO<Env, B, E>,
    _ zio: ZIO<Env, A, E>
) -> ZIO<Env, B, E> {
    zio >>- fn
}

// (>=>) :: (x -> ZIO<env, a, e>) -> (a -> ZIO<env, b, e>) -> (x -> ZIO<env, b, e>)
public func >=> <Env: Sendable, X: Sendable, A: Sendable, B: Sendable, E: Error & Sendable>(
    _ f: @escaping @Sendable (X) -> ZIO<Env, A, E>,
    _ g: @escaping @Sendable (A) -> ZIO<Env, B, E>
) -> @Sendable (X) -> ZIO<Env, B, E> {
    ZIO.kleisli(f, g)
}

// (<=<) :: (a -> ZIO<env, b, e>) -> (x -> ZIO<env, a, e>) -> (x -> ZIO<env, b, e>)
public func <=< <Env: Sendable, X: Sendable, A: Sendable, B: Sendable, E: Error & Sendable>(
    _ g: @escaping @Sendable (A) -> ZIO<Env, B, E>,
    _ f: @escaping @Sendable (X) -> ZIO<Env, A, E>
) -> @Sendable (X) -> ZIO<Env, B, E> {
    ZIO.kleisli(f, g)
}
