import CoreFP

// MARK: - Functor

public extension ZIO {
    // map :: (a -> b) -> ZIO<env, a, e> -> ZIO<env, b, e>
    func map<B: Sendable>(_ fn: @escaping @Sendable (Success) -> B) -> ZIO<Env, B, Failure> {
        ZIO<Env, B, Failure> { env in run(env).map { $0.map(fn) } }
    }

    // fmap :: (a -> b) -> ZIO<env, a, e> -> ZIO<env, b, e>
    static func fmap<B: Sendable>(
        _ fn: @escaping @Sendable (Success) -> B
    ) -> @Sendable (ZIO<Env, Success, Failure>) -> ZIO<Env, B, Failure> {
        { @Sendable zio in zio.map(fn) }
    }

    func replace<B: Sendable>(_ value: B) -> ZIO<Env, B, Failure> {
        map(const(value))
    }

    // mapError :: (e -> e2) -> ZIO<env, a, e> -> ZIO<env, a, e2>
    func mapError<F2: Error & Sendable>(
        _ fn: @escaping @Sendable (Failure) -> F2
    ) -> ZIO<Env, Success, F2> {
        ZIO<Env, Success, F2> { env in run(env).map { $0.mapError(fn) } }
    }
}

// mapZIO :: (a -> b) -> ZIO<env, a, e> -> ZIO<env, b, e>
public func mapZIO<Env: Sendable, A: Sendable, B: Sendable, E: Error & Sendable>(
    _ fn: @escaping @Sendable (A) -> B,
    _ zio: ZIO<Env, A, E>
) -> ZIO<Env, B, E> {
    zio.map(fn)
}

// fmapZIO :: (a -> b) -> ZIO<env, a, e> -> ZIO<env, b, e>
public func fmapZIO<Env: Sendable, A: Sendable, B: Sendable, E: Error & Sendable>(
    _ fn: @escaping @Sendable (A) -> B
) -> @Sendable (ZIO<Env, A, E>) -> ZIO<Env, B, E> {
    { @Sendable zio in zio.map(fn) }
}
