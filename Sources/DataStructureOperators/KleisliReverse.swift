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
) -> @Sendable (B0) -> Either<A, B1> { fn1 >=> fn2 }

/// `func` for `Either`.
public func <=< <L: Sendable, A: Sendable, B: Sendable, C: Sendable>(
    _ fn2: @escaping @Sendable (B) -> Either<L, C?>,
    _ fn1: @escaping @Sendable (A) -> Either<L, B?>
) -> @Sendable (A) -> Either<L, C?> { fn1 >=> fn2 }

/// `func` for `Either`.
public func <=< <L: Sendable, A: Sendable, B: Sendable, C: Sendable, E: Error>(
    _ fn2: @escaping @Sendable (B) -> Either<L, Result<C, E>>,
    _ fn1: @escaping @Sendable (A) -> Either<L, Result<B, E>>
) -> @Sendable (A) -> Either<L, Result<C, E>> { fn1 >=> fn2 }

/// `func` for `Either`.
public func <=< <L: Sendable, W: Monoid, A: Sendable, B: Sendable, C: Sendable>(
    _ fn2: @escaping @Sendable (B) -> Either<L, Writer<W, C>>,
    _ fn1: @escaping @Sendable (A) -> Either<L, Writer<W, B>>
) -> @Sendable (A) -> Either<L, Writer<W, C>> { fn1 >=> fn2 }

/// `func` for `Either`.
public func <=< <L: Sendable, A: Sendable, B: Sendable, C: Sendable>(
    _ fn2: @escaping @Sendable (B) -> Either<L, C>?,
    _ fn1: @escaping @Sendable (A) -> Either<L, B>?
) -> @Sendable (A) -> Either<L, C>? { fn1 >=> fn2 }

/// `func` for `Either`.
public func <=< <L: Sendable, A: Sendable, B: Sendable, C: Sendable>(
    _ fn2: @escaping @Sendable (B) -> [Either<L, C>],
    _ fn1: @escaping @Sendable (A) -> [Either<L, B>]
) -> @Sendable (A) -> [Either<L, C>] { fn1 >=> fn2 }

// MARK: - These

/// Reverse Kleisli composition for `These`.
/// `g <=< f` is equivalent to `f >=> g`.
public func <=< <A: Semigroup, B0, B, B1>(
    _ fn2: @escaping @Sendable (B) -> These<A, B1>,
    _ fn1: @escaping @Sendable (B0) -> These<A, B>
) -> @Sendable (B0) -> These<A, B1> { fn1 >=> fn2 }

// MARK: - Reader

/// `func` for `Reader`.
public func <=< <Env: Sendable, O0: Sendable, O: Sendable, O1: Sendable>(
    _ fn2: @escaping @Sendable (O) -> Reader<Env, O1>,
    _ fn1: @escaping @Sendable (O0) -> Reader<Env, O>
) -> @Sendable (O0) -> Reader<Env, O1> { fn1 >=> fn2 }

#if canImport(Combine)
    import Combine

    /// `func` for `PublisherT + Either`.
    @available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
    public func <=< <L, A, B, C, E: Error>(
        _ fn2: @escaping @Sendable (B) -> AnyPublisher<Either<L, C>, E>,
        _ fn1: @escaping @Sendable (A) -> AnyPublisher<Either<L, B>, E>
    ) -> @Sendable (A) -> AnyPublisher<Either<L, C>, E> { fn1 >=> fn2 }

    /// `func` for `PublisherT + Writer`.
    @available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
    public func <=< <W: Monoid, A, B, C, E: Error>(
        _ fn2: @escaping @Sendable (B) -> AnyPublisher<Writer<W, C>, E>,
        _ fn1: @escaping @Sendable (A) -> AnyPublisher<Writer<W, B>, E>
    ) -> @Sendable (A) -> AnyPublisher<Writer<W, C>, E> { fn1 >=> fn2 }

#endif

// MARK: - Stateful

/// `func` for `Stateful`.
public func <=< <S: Sendable, O0: Sendable, A: Sendable, B: Sendable>(
    _ fn2: @escaping @Sendable (A) -> Stateful<S, B>,
    _ fn1: @escaping @Sendable (O0) -> Stateful<S, A>
) -> @Sendable (O0) -> Stateful<S, B> { fn1 >=> fn2 }

/// `func` for `Stateful`.
public func <=< <S: Sendable, A: Sendable, B: Sendable, C: Sendable>(
    _ fn2: @escaping @Sendable (B) -> Stateful<S, C?>,
    _ fn1: @escaping @Sendable (A) -> Stateful<S, B?>
) -> @Sendable (A) -> Stateful<S, C?> { fn1 >=> fn2 }

/// `func` for `Stateful`.
public func <=< <S: Sendable, L: Sendable, A: Sendable, B: Sendable, C: Sendable>(
    _ fn2: @escaping @Sendable (B) -> Stateful<S, Either<L, C>>,
    _ fn1: @escaping @Sendable (A) -> Stateful<S, Either<L, B>>
) -> @Sendable (A) -> Stateful<S, Either<L, C>> { fn1 >=> fn2 }

/// `func` for `Stateful`.
public func <=< <S: Sendable, A: Sendable, B: Sendable, C: Sendable, E: Error>(
    _ fn2: @escaping @Sendable (B) -> Stateful<S, Result<C, E>>,
    _ fn1: @escaping @Sendable (A) -> Stateful<S, Result<B, E>>
) -> @Sendable (A) -> Stateful<S, Result<C, E>> { fn1 >=> fn2 }

/// `func` for `Stateful`.
public func <=< <S: Sendable, W: Monoid, A: Sendable, B: Sendable, C: Sendable>(
    _ fn2: @escaping @Sendable (B) -> Stateful<S, Writer<W, C>>,
    _ fn1: @escaping @Sendable (A) -> Stateful<S, Writer<W, B>>
) -> @Sendable (A) -> Stateful<S, Writer<W, C>> { fn1 >=> fn2 }

// MARK: - Writer

/// `func` for `Writer`.
public func <=< <W: Monoid, O0: Sendable, A: Sendable, B: Sendable>(
    _ fn2: @escaping @Sendable (A) -> Writer<W, B>,
    _ fn1: @escaping @Sendable (O0) -> Writer<W, A>
) -> @Sendable (O0) -> Writer<W, B> { fn1 >=> fn2 }

/// `func` for `Writer`.
public func <=< <W: Monoid, A: Sendable, B: Sendable, C: Sendable>(
    _ fn2: @escaping @Sendable (B) -> Writer<W, C>?,
    _ fn1: @escaping @Sendable (A) -> Writer<W, B>?
) -> @Sendable (A) -> Writer<W, C>? { fn1 >=> fn2 }

/// `func` for `Writer`.
public func <=< <W: Monoid, A: Sendable, B: Sendable, C: Sendable>(
    _ fn2: @escaping @Sendable (B) -> [Writer<W, C>],
    _ fn1: @escaping @Sendable (A) -> [Writer<W, B>]
) -> @Sendable (A) -> [Writer<W, C>] { fn1 >=> fn2 }

/// `func` for `Writer`.
public func <=< <W: Monoid, A: Sendable, B: Sendable, C: Sendable, E: Error>(
    _ fn2: @escaping @Sendable (B) -> Result<Writer<W, C>, E>,
    _ fn1: @escaping @Sendable (A) -> Result<Writer<W, B>, E>
) -> @Sendable (A) -> Result<Writer<W, C>, E> { fn1 >=> fn2 }

// MARK: - NonEmpty

/// Reverse Kleisli composition for `NonEmptyTResult`.
/// `g <=< f` is equivalent to `f >=> g`.
public func <=< <A, B, C, E>(
    _ fn2: @escaping @Sendable (B) -> NonEmpty<Result<C, E>>,
    _ fn1: @escaping @Sendable (A) -> NonEmpty<Result<B, E>>
) -> @Sendable (A) -> NonEmpty<Result<C, E>> { fn1 >=> fn2 }
