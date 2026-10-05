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

#endif

// MARK: - Stateful

/// `func` for `Stateful`.
public func <=< <S: Sendable, O0: Sendable, A: Sendable, B: Sendable>(
    _ fn2: @escaping @Sendable (A) -> Stateful<S, B>,
    _ fn1: @escaping @Sendable (O0) -> Stateful<S, A>
) -> @Sendable (O0) -> Stateful<S, B> { fn1 >=> fn2 }

// MARK: - Writer

/// `func` for `Writer`.
public func <=< <W: Monoid, O0: Sendable, A: Sendable, B: Sendable>(
    _ fn2: @escaping @Sendable (A) -> Writer<W, B>,
    _ fn1: @escaping @Sendable (O0) -> Writer<W, A>
) -> @Sendable (O0) -> Writer<W, B> { fn1 >=> fn2 }
