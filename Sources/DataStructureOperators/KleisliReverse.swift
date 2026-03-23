import DataStructure
import CoreFP
import CoreFPOperators

// MARK: - Either

public func <=< <A, B0, B, B1>(
    _ fn2: @escaping (B) -> Either<A, B1>,
    _ fn1: @escaping (B0) -> Either<A, B>
) -> (B0) -> Either<A, B1> { fn1 >=> fn2 }

public func <=< <L, A, B, C>(
    _ fn2: @escaping (B) -> Either<L, [C]>,
    _ fn1: @escaping (A) -> Either<L, [B]>
) -> (A) -> Either<L, [C]> { fn1 >=> fn2 }

public func <=< <L, A, B, C>(
    _ fn2: @escaping (B) -> Either<L, C?>,
    _ fn1: @escaping (A) -> Either<L, B?>
) -> (A) -> Either<L, C?> { fn1 >=> fn2 }

public func <=< <L, A, B, C, E: Error>(
    _ fn2: @escaping (B) -> Either<L, Result<C, E>>,
    _ fn1: @escaping (A) -> Either<L, Result<B, E>>
) -> (A) -> Either<L, Result<C, E>> { fn1 >=> fn2 }

public func <=< <L, E: Semigroup, A, B, C>(
    _ fn2: @escaping (B) -> Either<L, Validation<E, C>>,
    _ fn1: @escaping (A) -> Either<L, Validation<E, B>>
) -> (A) -> Either<L, Validation<E, C>> { fn1 >=> fn2 }

public func <=< <L, W: Monoid, A, B, C>(
    _ fn2: @escaping (B) -> Writer<W, C>,
    _ fn1: @escaping (A) -> Either<L, Writer<W, B>>
) -> (A) -> Either<L, Writer<W, C>> { fn1 >=> fn2 }

public func <=< <L, S, A, B, C>(
    _ fn2: @escaping (B) -> Stateful<S, C>,
    _ fn1: @escaping (A) -> Either<L, Stateful<S, B>>
) -> (A) -> Either<L, Stateful<S, C>> { fn1 >=> fn2 }

public func <=< <L, A, B, C>(
    _ fn2: @escaping (B) -> Either<L, C>?,
    _ fn1: @escaping (A) -> Either<L, B>?
) -> (A) -> Either<L, C>? { fn1 >=> fn2 }

public func <=< <L, A, B, C>(
    _ fn2: @escaping (B) -> [Either<L, C>],
    _ fn1: @escaping (A) -> [Either<L, B>]
) -> (A) -> [Either<L, C>] { fn1 >=> fn2 }

// MARK: - Reader

public func <=< <Env, O0, O, O1>(
    _ fn2: @escaping (O) -> Reader<Env, O1>,
    _ fn1: @escaping (O0) -> Reader<Env, O>
) -> (O0) -> Reader<Env, O1> { fn1 >=> fn2 }

public func <=< <Env, A, B, C>(
    _ fn2: @escaping (B) -> Reader<Env, [C]>,
    _ fn1: @escaping (A) -> Reader<Env, [B]>
) -> (A) -> Reader<Env, [C]> { fn1 >=> fn2 }

public func <=< <Env, A, B, C>(
    _ fn2: @escaping (B) -> Reader<Env, C?>,
    _ fn1: @escaping (A) -> Reader<Env, B?>
) -> (A) -> Reader<Env, C?> { fn1 >=> fn2 }

public func <=< <Env, L, A, B, C>(
    _ fn2: @escaping (B) -> Reader<Env, Either<L, C>>,
    _ fn1: @escaping (A) -> Reader<Env, Either<L, B>>
) -> (A) -> Reader<Env, Either<L, C>> { fn1 >=> fn2 }

public func <=< <Env, A, B, C, E: Error>(
    _ fn2: @escaping (B) -> Reader<Env, Result<C, E>>,
    _ fn1: @escaping (A) -> Reader<Env, Result<B, E>>
) -> (A) -> Reader<Env, Result<C, E>> { fn1 >=> fn2 }

public func <=< <Env, E: Semigroup, A, B, C>(
    _ fn2: @escaping (B) -> Reader<Env, Validation<E, C>>,
    _ fn1: @escaping (A) -> Reader<Env, Validation<E, B>>
) -> (A) -> Reader<Env, Validation<E, C>> { fn1 >=> fn2 }

public func <=< <Env1, Env2, A, B, C>(
    _ fn2: @escaping (B) -> Reader<Env1, Reader<Env2, C>>,
    _ fn1: @escaping (A) -> Reader<Env1, Reader<Env2, B>>
) -> (A) -> Reader<Env1, Reader<Env2, C>> { fn1 >=> fn2 }

public func <=< <Env, W: Monoid, A, B, C>(
    _ fn2: @escaping (B) -> Writer<W, C>,
    _ fn1: @escaping (A) -> Reader<Env, Writer<W, B>>
) -> (A) -> Reader<Env, Writer<W, C>> { fn1 >=> fn2 }

public func <=< <Env, S, A, B, C>(
    _ fn2: @escaping (B) -> Stateful<S, C>,
    _ fn1: @escaping (A) -> Reader<Env, Stateful<S, B>>
) -> (A) -> Reader<Env, Stateful<S, C>> { fn1 >=> fn2 }

#if canImport(Combine)
import Combine

@available(macOS 13.0, iOS 16.0, tvOS 16.0, watchOS 9.0, *)
public func <=< <Env, A, B, C, E: Error>(
    _ fn2: @escaping (B) -> Reader<Env, any Publisher<C, E>>,
    _ fn1: @escaping (A) -> Reader<Env, any Publisher<B, E>>
) -> (A) -> Reader<Env, any Publisher<C, E>> { fn1 >=> fn2 }

#endif

public func <=< <Env: Sendable, A: Sendable, B: Sendable, C: Sendable>(
    _ fn2: @escaping @Sendable (B) -> Reader<Env, DeferredTask<C>>,
    _ fn1: @escaping @Sendable (A) -> Reader<Env, DeferredTask<B>>
) -> (A) -> Reader<Env, DeferredTask<C>> { fn1 >=> fn2 }

public func <=< <Env: Sendable, A: Sendable, B: Sendable, C: Sendable>(
    _ fn2: @escaping @Sendable (B) -> Reader<Env, DeferredStream<C>>,
    _ fn1: @escaping @Sendable (A) -> Reader<Env, DeferredStream<B>>
) -> (A) -> Reader<Env, DeferredStream<C>> { fn1 >=> fn2 }

// MARK: - Stateful

public func <=< <S, O0, A, B>(
    _ fn2: @escaping (A) -> Stateful<S, B>,
    _ fn1: @escaping (O0) -> Stateful<S, A>
) -> (O0) -> Stateful<S, B> { fn1 >=> fn2 }

public func <=< <S, A, B, C>(
    _ fn2: @escaping (B) -> Stateful<S, [C]>,
    _ fn1: @escaping (A) -> Stateful<S, [B]>
) -> (A) -> Stateful<S, [C]> { fn1 >=> fn2 }

public func <=< <S, A, B, C>(
    _ fn2: @escaping (B) -> Stateful<S, C?>,
    _ fn1: @escaping (A) -> Stateful<S, B?>
) -> (A) -> Stateful<S, C?> { fn1 >=> fn2 }

public func <=< <S, L, A, B, C>(
    _ fn2: @escaping (B) -> Stateful<S, Either<L, C>>,
    _ fn1: @escaping (A) -> Stateful<S, Either<L, B>>
) -> (A) -> Stateful<S, Either<L, C>> { fn1 >=> fn2 }

public func <=< <S, A, B, C, E: Error>(
    _ fn2: @escaping (B) -> Stateful<S, Result<C, E>>,
    _ fn1: @escaping (A) -> Stateful<S, Result<B, E>>
) -> (A) -> Stateful<S, Result<C, E>> { fn1 >=> fn2 }

public func <=< <S, E: Semigroup, A, B, C>(
    _ fn2: @escaping (B) -> Stateful<S, Validation<E, C>>,
    _ fn1: @escaping (A) -> Stateful<S, Validation<E, B>>
) -> (A) -> Stateful<S, Validation<E, C>> { fn1 >=> fn2 }

public func <=< <S, A, B, C>(
    _ fn2: @escaping (B) -> Stateful<S, C>,
    _ fn1: @escaping (A) -> Stateful<S, B>?
) -> (A) -> Stateful<S, C>? { fn1 >=> fn2 }

public func <=< <S, A, B, C>(
    _ fn2: @escaping (B) -> Stateful<S, C>,
    _ fn1: @escaping (A) -> [Stateful<S, B>]
) -> (A) -> [Stateful<S, C>] { fn1 >=> fn2 }

public func <=< <S, A, B, C, E: Error>(
    _ fn2: @escaping (B) -> Stateful<S, C>,
    _ fn1: @escaping (A) -> Result<Stateful<S, B>, E>
) -> (A) -> Result<Stateful<S, C>, E> { fn1 >=> fn2 }

// MARK: - Writer

public func <=< <W: Monoid, O0, A, B>(
    _ fn2: @escaping (A) -> Writer<W, B>,
    _ fn1: @escaping (O0) -> Writer<W, A>
) -> (O0) -> Writer<W, B> { fn1 >=> fn2 }

public func <=< <W: Monoid, A, B, C>(
    _ fn2: @escaping (B) -> Writer<W, [C]>,
    _ fn1: @escaping (A) -> Writer<W, [B]>
) -> (A) -> Writer<W, [C]> { fn1 >=> fn2 }

public func <=< <W: Monoid, A, B, C>(
    _ fn2: @escaping (B) -> Writer<W, C?>,
    _ fn1: @escaping (A) -> Writer<W, B?>
) -> (A) -> Writer<W, C?> { fn1 >=> fn2 }

public func <=< <W: Monoid, L, A, B, C>(
    _ fn2: @escaping (B) -> Writer<W, Either<L, C>>,
    _ fn1: @escaping (A) -> Writer<W, Either<L, B>>
) -> (A) -> Writer<W, Either<L, C>> { fn1 >=> fn2 }

public func <=< <W: Monoid, A, B, C, E: Error>(
    _ fn2: @escaping (B) -> Writer<W, Result<C, E>>,
    _ fn1: @escaping (A) -> Writer<W, Result<B, E>>
) -> (A) -> Writer<W, Result<C, E>> { fn1 >=> fn2 }

public func <=< <W: Monoid, E: Semigroup, A, B, C>(
    _ fn2: @escaping (B) -> Writer<W, Validation<E, C>>,
    _ fn1: @escaping (A) -> Writer<W, Validation<E, B>>
) -> (A) -> Writer<W, Validation<E, C>> { fn1 >=> fn2 }

public func <=< <W: Monoid, S, A, B, C>(
    _ fn2: @escaping (B) -> Writer<W, Stateful<S, C>>,
    _ fn1: @escaping (A) -> Writer<W, Stateful<S, B>>
) -> (A) -> Writer<W, Stateful<S, C>> { fn1 >=> fn2 }

public func <=< <W: Monoid, Env, A, B, C>(
    _ fn2: @escaping (B) -> Writer<W, Reader<Env, C>>,
    _ fn1: @escaping (A) -> Writer<W, Reader<Env, B>>
) -> (A) -> Writer<W, Reader<Env, C>> { fn1 >=> fn2 }

#if canImport(Combine)
import Combine

@available(macOS 13.0, iOS 16.0, tvOS 16.0, watchOS 9.0, *)
public func <=< <W: Monoid, A, B, C, E: Error>(
    _ fn2: @escaping (B) -> Writer<W, any Publisher<C, E>>,
    _ fn1: @escaping (A) -> Writer<W, any Publisher<B, E>>
) -> (A) -> Writer<W, any Publisher<C, E>> { fn1 >=> fn2 }

#endif

public func <=< <W: Monoid, A: Sendable, B: Sendable, C: Sendable>(
    _ fn2: @escaping @Sendable (B) -> Writer<W, DeferredTask<C>>,
    _ fn1: @escaping @Sendable (A) -> Writer<W, DeferredTask<B>>
) -> (A) -> Writer<W, DeferredTask<C>> { fn1 >=> fn2 }

public func <=< <W: Monoid, A: Sendable, B: Sendable, C: Sendable>(
    _ fn2: @escaping @Sendable (B) -> Writer<W, DeferredStream<C>>,
    _ fn1: @escaping @Sendable (A) -> Writer<W, DeferredStream<B>>
) -> (A) -> Writer<W, DeferredStream<C>> { fn1 >=> fn2 }

public func <=< <W: Monoid, A, B, C>(
    _ fn2: @escaping (B) -> Writer<W, C>,
    _ fn1: @escaping (A) -> Writer<W, B>?
) -> (A) -> Writer<W, C>? { fn1 >=> fn2 }

public func <=< <W: Monoid, A, B, C>(
    _ fn2: @escaping (B) -> Writer<W, C>,
    _ fn1: @escaping (A) -> [Writer<W, B>]
) -> (A) -> [Writer<W, C>] { fn1 >=> fn2 }

public func <=< <W: Monoid, A, B, C, E: Error>(
    _ fn2: @escaping (B) -> Writer<W, C>,
    _ fn1: @escaping (A) -> Result<Writer<W, B>, E>
) -> (A) -> Result<Writer<W, C>, E> { fn1 >=> fn2 }
