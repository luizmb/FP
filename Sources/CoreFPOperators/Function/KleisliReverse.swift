// SPDX-License-Identifier: Apache-2.0
import CoreFP

// MARK: - Reverse Kleisli composition (<=<) for standard monads
//
// <=< is the right-to-left version of >=>:
//   g <=< f  ==  f >=> g
//
// All overloads delegate to the corresponding >=> overload, which means
// the semantics (and copy cost) are identical. The overloads here cover
// the same set of monads as the >=> operator in the adjacent >=> files.

// MARK: - Optional

/// Reverse Kleisli composition for `Optional`.
///
/// `g <=< f` is `f >=> g`. Reads right-to-left: `g` is applied after `f`.
///
/// ```swift
/// let safeDiv: (Int) -> Int? = { $0 != 0 ? 100 / $0 : nil }
/// let toNonNegative: (Int) -> Int? = { $0 >= 0 ? $0 : nil }
/// let safeDivNonNeg = safeDiv <=< toNonNegative
/// // equivalent to: toNonNegative >=> safeDiv
/// ```
public func <=< <A0, A, A1>(
    _ fn2: @escaping @Sendable (A) -> A1?,
    _ fn1: @escaping @Sendable (A0) -> A?
) -> (A0) -> A1? { fn1 >=> fn2 }

// MARK: - Array

/// `func` for `Array`.
public func <=< <A0, A, A1>(
    _ fn2: @escaping @Sendable (A) -> [A1],
    _ fn1: @escaping @Sendable (A0) -> [A]
) -> (A0) -> [A1] { fn1 >=> fn2 }

// MARK: - Result

/// `func` for `Result`.
public func <=< <A0, A, A1, B>(
    _ fn2: @escaping @Sendable (A) -> Result<A1, B>,
    _ fn1: @escaping @Sendable (A0) -> Result<A, B>
) -> (A0) -> Result<A1, B> { fn1 >=> fn2 }

// MARK: - Publisher

#if canImport(Combine)
import Combine

/// `func` for `Publisher`.
@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public func <=< <A0, A, A1, B: Error, P1: Publisher, P2: Publisher>(
    _ fn2: @escaping @Sendable (A) -> P2,
    _ fn1: @escaping @Sendable (A0) -> P1
) -> (A0) -> any Publisher<A1, B>
where P1.Output == A, P1.Failure == B, P2.Output == A1, P2.Failure == B { fn1 >=> fn2 }

#endif

// MARK: - AsyncSequence

/// `func` for `AsyncSequence`.
@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public func <=< <A, B: AsyncSequence, C: AsyncSequence>(
    _ fn2: @escaping @Sendable (B.Element) async throws -> C,
    _ fn1: @escaping @Sendable (A) async throws -> B
) -> (A) async throws -> AsyncThrowingFlatMapSequence<AsyncThrowingMapSequence<B, C>, C> { fn1 >=> fn2 }
