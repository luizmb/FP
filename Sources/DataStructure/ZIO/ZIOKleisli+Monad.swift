import CoreFP

// MARK: - Monad (Input fixed, sequences ZIO results)

public extension ZIOKleisli {
    // pure :: a -> ZIOKleisli<i, env, a, e>  — ignores input, wraps a pure success
    static func pure(_ value: Success) -> ZIOKleisli<Input, Env, Success, Failure> {
        ZIOKleisli { _ in .pure(value) }
    }

    // flatMap :: (a -> ZIOKleisli<i, env, b, e>) -> ZIOKleisli<i, env, a, e> -> ZIOKleisli<i, env, b, e>
    // Threads the same Input into both sides; failure short-circuits.
    func flatMap<B: Sendable>(
        _ fn: @escaping @Sendable (Success) -> ZIOKleisli<Input, Env, B, Failure>
    ) -> ZIOKleisli<Input, Env, B, Failure> {
        ZIOKleisli<Input, Env, B, Failure> { input in
            run(input).flatMap { a in fn(a).run(input) }
        }
    }

    // bind :: (a -> ZIOKleisli<i, env, b, e>) -> ZIOKleisli<i, env, a, e> -> ZIOKleisli<i, env, b, e>
    static func bind<B: Sendable>(
        _ fn: @escaping @Sendable (Success) -> ZIOKleisli<Input, Env, B, Failure>
    ) -> @Sendable (ZIOKleisli<Input, Env, Success, Failure>) -> ZIOKleisli<Input, Env, B, Failure> {
        { @Sendable k in k.flatMap(fn) }
    }

    // join :: ZIOKleisli<i, env, ZIOKleisli<i, env, a, e>, e> -> ZIOKleisli<i, env, a, e>
    static func join<A: Sendable>(
        _ nested: ZIOKleisli<Input, Env, ZIOKleisli<Input, Env, A, Failure>, Failure>
    ) -> ZIOKleisli<Input, Env, A, Failure> where Success == ZIOKleisli<Input, Env, A, Failure> {
        nested.flatMap(id)
    }

    // flatMapError :: (e -> ZIOKleisli<i, env, a, e2>) -> ZIOKleisli<i, env, a, e> -> ZIOKleisli<i, env, a, e2>
    func flatMapError<F2: Error & Sendable>(
        _ fn: @escaping @Sendable (Failure) -> ZIOKleisli<Input, Env, Success, F2>
    ) -> ZIOKleisli<Input, Env, Success, F2> {
        ZIOKleisli<Input, Env, Success, F2> { input in
            run(input).flatMapError { e in fn(e).run(input) }
        }
    }

    func void() -> ZIOKleisli<Input, Env, Void, Failure> {
        map(ignore)
    }
}

// MARK: - Kleisli category composition (changes Input type)

public extension ZIOKleisli {
    // andThen :: ZIOKleisli<i, env, a, e> -> ZIOKleisli<a, env, b, e> -> ZIOKleisli<i, env, b, e>
    // Feeds this arrow's output as the next arrow's input.
    // This is the >=> operator at the ZIOKleisli level.
    func andThen<B: Sendable>(
        _ next: ZIOKleisli<Success, Env, B, Failure>
    ) -> ZIOKleisli<Input, Env, B, Failure> {
        ZIOKleisli<Input, Env, B, Failure> { input in
            run(input).flatMap { a in next.run(a) }
        }
    }

    // compose :: ZIOKleisli<a, env, b, e> -> ZIOKleisli<i, env, a, e> -> ZIOKleisli<i, env, b, e>
    // Reverse of andThen: feed prev's output as self's input.
    func compose<PrevInput: Sendable>(
        _ prev: ZIOKleisli<PrevInput, Env, Input, Failure>
    ) -> ZIOKleisli<PrevInput, Env, Success, Failure> {
        prev.andThen(self)
    }

    // kleisli :: ZIOKleisli<i, env, a, e> -> ZIOKleisli<a, env, b, e> -> ZIOKleisli<i, env, b, e>
    static func kleisli<I: Sendable, B: Sendable>(
        _ f: ZIOKleisli<I, Env, Success, Failure>,
        _ g: ZIOKleisli<Success, Env, B, Failure>
    ) -> ZIOKleisli<I, Env, B, Failure> {
        f.andThen(g)
    }
}

// flatMapZIOKleisli :: ZIOKleisli<i, env, a, e> -> (a -> ZIOKleisli<i, env, b, e>) -> ZIOKleisli<i, env, b, e>
public func flatMapZIOKleisli<I: Sendable, Env: Sendable, A: Sendable, B: Sendable, E: Error & Sendable>(
    _ k: ZIOKleisli<I, Env, A, E>,
    _ fn: @escaping @Sendable (A) -> ZIOKleisli<I, Env, B, E>
) -> ZIOKleisli<I, Env, B, E> {
    k.flatMap(fn)
}

// bindZIOKleisli :: (a -> ZIOKleisli<i, env, b, e>) -> ZIOKleisli<i, env, a, e> -> ZIOKleisli<i, env, b, e>
public func bindZIOKleisli<I: Sendable, Env: Sendable, A: Sendable, B: Sendable, E: Error & Sendable>(
    _ fn: @escaping @Sendable (A) -> ZIOKleisli<I, Env, B, E>
) -> @Sendable (ZIOKleisli<I, Env, A, E>) -> ZIOKleisli<I, Env, B, E> {
    { @Sendable k in k.flatMap(fn) }
}
