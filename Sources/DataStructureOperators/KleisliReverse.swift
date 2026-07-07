// SPDX-License-Identifier: Apache-2.0
import CoreFP
import CoreFPOperators
import DataStructure

// MARK: - Reverse Kleisli composition (<=<) for DataStructure types

//
// This file provides <=< overloads for all DataStructure monad types:
// Either, Reader, Stateful, Writer.
//
// Each overload delegates to the corresponding >=> overload.
// g <=< f  ==  f >=> g
//
// The overloads cover:
//   - Base monad: (A -> M<B>) <=< (X -> M<A>) = (X -> M<B>)
//   - Transformer combinations: M1<M2<_>>-returning Kleisli arrows

// MARK: - Either

/// Reverse Kleisli composition for `Either`.
/// `g <=< f` is equivalent to `f >=> g`.
public func <=< <A: Sendable, B0: Sendable, B: Sendable, B1: Sendable>(
    _ fn2: @escaping @Sendable (B) -> Either<A, B1>,
    _ fn1: @escaping @Sendable (B0) -> Either<A, B>
) -> (B0) -> Either<A, B1> { fn1 >=> fn2 }

/// `func` for `Either`.
public func <=< <L: Sendable, A: Sendable, B: Sendable, C: Sendable>(
    _ fn2: @escaping @Sendable (B) -> Either<L, [C]>,
    _ fn1: @escaping @Sendable (A) -> Either<L, [B]>
) -> (A) -> Either<L, [C]> { fn1 >=> fn2 }

/// `func` for `Either`.
public func <=< <L: Sendable, A: Sendable, B: Sendable, C: Sendable>(
    _ fn2: @escaping @Sendable (B) -> Either<L, C?>,
    _ fn1: @escaping @Sendable (A) -> Either<L, B?>
) -> (A) -> Either<L, C?> { fn1 >=> fn2 }

/// `func` for `Either`.
public func <=< <L: Sendable, A: Sendable, B: Sendable, C: Sendable, E: Error>(
    _ fn2: @escaping @Sendable (B) -> Either<L, Result<C, E>>,
    _ fn1: @escaping @Sendable (A) -> Either<L, Result<B, E>>
) -> (A) -> Either<L, Result<C, E>> { fn1 >=> fn2 }

/// `func` for `Either`.
public func <=< <L: Sendable, W: Monoid, A: Sendable, B: Sendable, C: Sendable>(
    _ fn2: @escaping @Sendable (B) -> Writer<W, C>,
    _ fn1: @escaping @Sendable (A) -> Either<L, Writer<W, B>>
) -> (A) -> Either<L, Writer<W, C>> { fn1 >=> fn2 }

/// `func` for `Either`.
public func <=< <L: Sendable, S: Sendable, A: Sendable, B: Sendable, C: Sendable>(
    _ fn2: @escaping @Sendable (B) -> Stateful<S, C>,
    _ fn1: @escaping @Sendable (A) -> Either<L, Stateful<S, B>>
) -> (A) -> Either<L, Stateful<S, C>> { fn1 >=> fn2 }

/// `func` for `Either`.
public func <=< <L: Sendable, A: Sendable, B: Sendable, C: Sendable>(
    _ fn2: @escaping @Sendable (B) -> Either<L, C>?,
    _ fn1: @escaping @Sendable (A) -> Either<L, B>?
) -> (A) -> Either<L, C>? { fn1 >=> fn2 }

/// `func` for `Either`.
public func <=< <L: Sendable, A: Sendable, B: Sendable, C: Sendable>(
    _ fn2: @escaping @Sendable (B) -> [Either<L, C>],
    _ fn1: @escaping @Sendable (A) -> [Either<L, B>]
) -> (A) -> [Either<L, C>] { fn1 >=> fn2 }

// MARK: - Reader

/// `func` for `Reader`.
public func <=< <Env: Sendable, O0: Sendable, O: Sendable, O1: Sendable>(
    _ fn2: @escaping @Sendable (O) -> Reader<Env, O1>,
    _ fn1: @escaping @Sendable (O0) -> Reader<Env, O>
) -> (O0) -> Reader<Env, O1> { fn1 >=> fn2 }

/// `func` for `Reader`.
public func <=< <Env: Sendable, A: Sendable, B: Sendable, C: Sendable>(
    _ fn2: @escaping @Sendable (B) -> Reader<Env, [C]>,
    _ fn1: @escaping @Sendable (A) -> Reader<Env, [B]>
) -> (A) -> Reader<Env, [C]> { fn1 >=> fn2 }

/// `func` for `Reader`.
public func <=< <Env: Sendable, A: Sendable, B: Sendable, C: Sendable>(
    _ fn2: @escaping @Sendable (B) -> Reader<Env, C?>,
    _ fn1: @escaping @Sendable (A) -> Reader<Env, B?>
) -> (A) -> Reader<Env, C?> { fn1 >=> fn2 }

/// `func` for `Reader`.
public func <=< <Env: Sendable, L: Sendable, A: Sendable, B: Sendable, C: Sendable>(
    _ fn2: @escaping @Sendable (B) -> Reader<Env, Either<L, C>>,
    _ fn1: @escaping @Sendable (A) -> Reader<Env, Either<L, B>>
) -> (A) -> Reader<Env, Either<L, C>> { fn1 >=> fn2 }

/// `func` for `Reader`.
public func <=< <Env: Sendable, A: Sendable, B: Sendable, C: Sendable, E: Error>(
    _ fn2: @escaping @Sendable (B) -> Reader<Env, Result<C, E>>,
    _ fn1: @escaping @Sendable (A) -> Reader<Env, Result<B, E>>
) -> (A) -> Reader<Env, Result<C, E>> { fn1 >=> fn2 }

/// `func` for `Reader`.
public func <=< <Env1: Sendable, Env2: Sendable, A: Sendable, B: Sendable, C: Sendable>(
    _ fn2: @escaping @Sendable (B) -> Reader<Env1, Reader<Env2, C>>,
    _ fn1: @escaping @Sendable (A) -> Reader<Env1, Reader<Env2, B>>
) -> (A) -> Reader<Env1, Reader<Env2, C>> { fn1 >=> fn2 }

/// `func` for `Reader`.
public func <=< <Env: Sendable, W: Monoid, A: Sendable, B: Sendable, C: Sendable>(
    _ fn2: @escaping @Sendable (B) -> Writer<W, C>,
    _ fn1: @escaping @Sendable (A) -> Reader<Env, Writer<W, B>>
) -> (A) -> Reader<Env, Writer<W, C>> { fn1 >=> fn2 }

/// `func` for `Reader`.
public func <=< <Env: Sendable, S: Sendable, A: Sendable, B: Sendable, C: Sendable>(
    _ fn2: @escaping @Sendable (B) -> Stateful<S, C>,
    _ fn1: @escaping @Sendable (A) -> Reader<Env, Stateful<S, B>>
) -> (A) -> Reader<Env, Stateful<S, C>> { fn1 >=> fn2 }

#if canImport(Combine)
    import Combine

    /// `func` for `Reader`.
    @available(macOS 13.0, iOS 16.0, tvOS 16.0, watchOS 9.0, *)
    public func <=< <Env: Sendable, A: Sendable, B: Sendable, C: Sendable, E: Error>(
        _ fn2: @escaping @Sendable (B) -> Reader<Env, any Publisher<C, E>>,
        _ fn1: @escaping @Sendable (A) -> Reader<Env, any Publisher<B, E>>
    ) -> (A) -> Reader<Env, any Publisher<C, E>> { fn1 >=> fn2 }

#endif

// MARK: - Stateful

/// `func` for `Stateful`.
public func <=< <S: Sendable, O0: Sendable, A: Sendable, B: Sendable>(
    _ fn2: @escaping @Sendable (A) -> Stateful<S, B>,
    _ fn1: @escaping @Sendable (O0) -> Stateful<S, A>
) -> (O0) -> Stateful<S, B> { fn1 >=> fn2 }

/// `func` for `Stateful`.
public func <=< <S: Sendable, A: Sendable, B: Sendable, C: Sendable>(
    _ fn2: @escaping @Sendable (B) -> Stateful<S, [C]>,
    _ fn1: @escaping @Sendable (A) -> Stateful<S, [B]>
) -> (A) -> Stateful<S, [C]> { fn1 >=> fn2 }

/// `func` for `Stateful`.
public func <=< <S: Sendable, A: Sendable, B: Sendable, C: Sendable>(
    _ fn2: @escaping @Sendable (B) -> Stateful<S, C?>,
    _ fn1: @escaping @Sendable (A) -> Stateful<S, B?>
) -> (A) -> Stateful<S, C?> { fn1 >=> fn2 }

/// `func` for `Stateful`.
public func <=< <S: Sendable, L: Sendable, A: Sendable, B: Sendable, C: Sendable>(
    _ fn2: @escaping @Sendable (B) -> Stateful<S, Either<L, C>>,
    _ fn1: @escaping @Sendable (A) -> Stateful<S, Either<L, B>>
) -> (A) -> Stateful<S, Either<L, C>> { fn1 >=> fn2 }

/// `func` for `Stateful`.
public func <=< <S: Sendable, A: Sendable, B: Sendable, C: Sendable, E: Error>(
    _ fn2: @escaping @Sendable (B) -> Stateful<S, Result<C, E>>,
    _ fn1: @escaping @Sendable (A) -> Stateful<S, Result<B, E>>
) -> (A) -> Stateful<S, Result<C, E>> { fn1 >=> fn2 }

/// `func` for `Stateful`.
public func <=< <S: Sendable, A: Sendable, B: Sendable, C: Sendable>(
    _ fn2: @escaping @Sendable (B) -> Stateful<S, C>,
    _ fn1: @escaping @Sendable (A) -> Stateful<S, B>?
) -> (A) -> Stateful<S, C>? { fn1 >=> fn2 }

/// `func` for `Stateful`.
public func <=< <S: Sendable, A: Sendable, B: Sendable, C: Sendable>(
    _ fn2: @escaping @Sendable (B) -> Stateful<S, C>,
    _ fn1: @escaping @Sendable (A) -> [Stateful<S, B>]
) -> (A) -> [Stateful<S, C>] { fn1 >=> fn2 }

/// `func` for `Stateful`.
public func <=< <S: Sendable, A: Sendable, B: Sendable, C: Sendable, E: Error>(
    _ fn2: @escaping @Sendable (B) -> Stateful<S, C>,
    _ fn1: @escaping @Sendable (A) -> Result<Stateful<S, B>, E>
) -> (A) -> Result<Stateful<S, C>, E> { fn1 >=> fn2 }

// MARK: - Writer

/// `func` for `Writer`.
public func <=< <W: Monoid, O0: Sendable, A: Sendable, B: Sendable>(
    _ fn2: @escaping @Sendable (A) -> Writer<W, B>,
    _ fn1: @escaping @Sendable (O0) -> Writer<W, A>
) -> (O0) -> Writer<W, B> { fn1 >=> fn2 }

/// `func` for `Writer`.
public func <=< <W: Monoid, A: Sendable, B: Sendable, C: Sendable>(
    _ fn2: @escaping @Sendable (B) -> Writer<W, [C]>,
    _ fn1: @escaping @Sendable (A) -> Writer<W, [B]>
) -> (A) -> Writer<W, [C]> { fn1 >=> fn2 }

/// `func` for `Writer`.
public func <=< <W: Monoid, A: Sendable, B: Sendable, C: Sendable>(
    _ fn2: @escaping @Sendable (B) -> Writer<W, C?>,
    _ fn1: @escaping @Sendable (A) -> Writer<W, B?>
) -> (A) -> Writer<W, C?> { fn1 >=> fn2 }

/// `func` for `Writer`.
public func <=< <W: Monoid, L: Sendable, A: Sendable, B: Sendable, C: Sendable>(
    _ fn2: @escaping @Sendable (B) -> Writer<W, Either<L, C>>,
    _ fn1: @escaping @Sendable (A) -> Writer<W, Either<L, B>>
) -> (A) -> Writer<W, Either<L, C>> { fn1 >=> fn2 }

/// `func` for `Writer`.
public func <=< <W: Monoid, A: Sendable, B: Sendable, C: Sendable, E: Error>(
    _ fn2: @escaping @Sendable (B) -> Writer<W, Result<C, E>>,
    _ fn1: @escaping @Sendable (A) -> Writer<W, Result<B, E>>
) -> (A) -> Writer<W, Result<C, E>> { fn1 >=> fn2 }

/// `func` for `Writer`.
public func <=< <W: Monoid, S: Sendable, A: Sendable, B: Sendable, C: Sendable>(
    _ fn2: @escaping @Sendable (B) -> Writer<W, Stateful<S, C>>,
    _ fn1: @escaping @Sendable (A) -> Writer<W, Stateful<S, B>>
) -> (A) -> Writer<W, Stateful<S, C>> { fn1 >=> fn2 }

/// `func` for `Writer`.
public func <=< <W: Monoid, Env: Sendable, A: Sendable, B: Sendable, C: Sendable>(
    _ fn2: @escaping @Sendable (B) -> Writer<W, Reader<Env, C>>,
    _ fn1: @escaping @Sendable (A) -> Writer<W, Reader<Env, B>>
) -> (A) -> Writer<W, Reader<Env, C>> { fn1 >=> fn2 }

#if canImport(Combine)
    import Combine
    import CoreFPOperators

    /// `func` for `Writer`.
    @available(macOS 13.0, iOS 16.0, tvOS 16.0, watchOS 9.0, *)
    public func <=< <W: Monoid, A: Sendable, B: Sendable, C: Sendable, E: Error>(
        _ fn2: @escaping @Sendable (B) -> Writer<W, any Publisher<C, E>>,
        _ fn1: @escaping @Sendable (A) -> Writer<W, any Publisher<B, E>>
    ) -> (A) -> Writer<W, any Publisher<C, E>> { fn1 >=> fn2 }

#endif

/// `func` for `Writer`.
public func <=< <W: Monoid, A: Sendable, B: Sendable, C: Sendable>(
    _ fn2: @escaping @Sendable (B) -> Writer<W, C>,
    _ fn1: @escaping @Sendable (A) -> Writer<W, B>?
) -> (A) -> Writer<W, C>? { fn1 >=> fn2 }

/// `func` for `Writer`.
public func <=< <W: Monoid, A: Sendable, B: Sendable, C: Sendable>(
    _ fn2: @escaping @Sendable (B) -> Writer<W, C>,
    _ fn1: @escaping @Sendable (A) -> [Writer<W, B>]
) -> (A) -> [Writer<W, C>] { fn1 >=> fn2 }

/// `func` for `Writer`.
public func <=< <W: Monoid, A: Sendable, B: Sendable, C: Sendable, E: Error>(
    _ fn2: @escaping @Sendable (B) -> Writer<W, C>,
    _ fn1: @escaping @Sendable (A) -> Result<Writer<W, B>, E>
) -> (A) -> Result<Writer<W, C>, E> { fn1 >=> fn2 }
