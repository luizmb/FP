// SPDX-License-Identifier: Apache-2.0
/// A ``Semigroup`` that keeps the smaller of two values, under a general `Comparable` ordering.
///
/// Unlike `NumericMonoid<T>.Min` (which requires `T: HasMax` to supply an identity of
/// `T.max`), `Min` works for **any** `Comparable & Sendable` type — `String`, `Date`, custom
/// types, and so on. The trade-off: there is no universal "positive infinity" for an
/// arbitrary `Comparable` type, so `Min` conforms only to ``Semigroup``, never ``Monoid``.
///
/// | Type | Operation | Identity |
/// |------|-----------|---------|
/// | `Min<T>` | `Swift.min(_:_:)` | none — `Semigroup` only |
///
/// ## Example
///
/// ```swift
/// let smallest = sconcat(Min(5), [Min(1), Min(9), Min(3)])
/// smallest.rawValue   // 1
///
/// // Using <> (requires CoreFPOperators):
/// let result = Min(5) <> Min(1) <> Min(9)
/// result.rawValue      // 1
/// ```
///
/// - SeeAlso: ``Max``, ``Semigroup``, ``NumericMonoid``
public struct Min<T: Comparable & Sendable>: Semigroup, RawRepresentable {
    public let rawValue: T

    public init(_ rawValue: T) {
        self.rawValue = rawValue
    }

    public init?(rawValue: T) {
        self.init(rawValue)
    }

    public static func combine(_ lhs: Min, _ rhs: Min) -> Min {
        Min(Swift.min(lhs.rawValue, rhs.rawValue))
    }
}

/// A ``Semigroup`` that keeps the larger of two values, under a general `Comparable` ordering.
///
/// The `Max` counterpart to ``Min`` — see its documentation for why this conforms only to
/// ``Semigroup`` and not ``Monoid`` for a general `Comparable` type.
///
/// | Type | Operation | Identity |
/// |------|-----------|---------|
/// | `Max<T>` | `Swift.max(_:_:)` | none — `Semigroup` only |
///
/// ## Example
///
/// ```swift
/// let largest = sconcat(Max(5), [Max(1), Max(9), Max(3)])
/// largest.rawValue   // 9
///
/// // Using <> (requires CoreFPOperators):
/// let result = Max(5) <> Max(1) <> Max(9)
/// result.rawValue     // 9
/// ```
///
/// - SeeAlso: ``Min``, ``Semigroup``, ``NumericMonoid``
public struct Max<T: Comparable & Sendable>: Semigroup, RawRepresentable {
    public let rawValue: T

    public init(_ rawValue: T) {
        self.rawValue = rawValue
    }

    public init?(rawValue: T) {
        self.init(rawValue)
    }

    public static func combine(_ lhs: Max, _ rhs: Max) -> Max {
        Max(Swift.max(lhs.rawValue, rhs.rawValue))
    }
}

/// A ``Semigroup`` that always keeps the first (left-hand) value it sees.
///
/// Works for any `Sendable` type — no `Comparable` or `Equatable` constraint is needed,
/// since `combine` never inspects the values, only their position. There is no universal
/// identity element for an arbitrary type, so `First` conforms only to ``Semigroup``.
///
/// | Type | Operation | Identity |
/// |------|-----------|---------|
/// | `First<T>` | keep `lhs` | none — `Semigroup` only |
///
/// ## Example
///
/// ```swift
/// let winner = sconcat(First("prod"), [First("staging"), First("dev")])
/// winner.rawValue   // "prod"
///
/// // Using <> (requires CoreFPOperators):
/// let result = First("prod") <> First("staging")
/// result.rawValue    // "prod"
/// ```
///
/// - SeeAlso: ``Last``, ``Semigroup``
public struct First<T: Sendable>: Semigroup, RawRepresentable {
    public let rawValue: T

    public init(_ rawValue: T) {
        self.rawValue = rawValue
    }

    public init?(rawValue: T) {
        self.init(rawValue)
    }

    public static func combine(_ lhs: First, _: First) -> First {
        lhs
    }
}

/// A ``Semigroup`` that always keeps the last (right-hand) value it sees.
///
/// The `Last` counterpart to ``First`` — see its documentation for the same reasoning about
/// why this conforms only to ``Semigroup``.
///
/// | Type | Operation | Identity |
/// |------|-----------|---------|
/// | `Last<T>` | keep `rhs` | none — `Semigroup` only |
///
/// ## Example
///
/// ```swift
/// let winner = sconcat(Last("prod"), [Last("staging"), Last("dev")])
/// winner.rawValue   // "dev"
///
/// // Using <> (requires CoreFPOperators):
/// let result = Last("prod") <> Last("staging")
/// result.rawValue    // "staging"
/// ```
///
/// - SeeAlso: ``First``, ``Semigroup``
public struct Last<T: Sendable>: Semigroup, RawRepresentable {
    public let rawValue: T

    public init(_ rawValue: T) {
        self.rawValue = rawValue
    }

    public init?(rawValue: T) {
        self.init(rawValue)
    }

    public static func combine(_: Last, _ rhs: Last) -> Last {
        rhs
    }
}

/// A ``Semigroup`` (and, when `T` is a ``Monoid``, also a ``Monoid``) that flips the order
/// in which its wrapped `Semigroup` combines its operands.
///
/// `Dual<T>.combine(l, r)` computes `T.combine(r.rawValue, l.rawValue)` — the operands are
/// swapped before delegating to the wrapped type's own `combine`. For a commutative
/// semigroup this has no observable effect; for a non-commutative one (string concatenation,
/// ``Endo`` composition, …) it reverses the effective direction of combination.
///
/// | Type | Operation | Identity |
/// |------|-----------|---------|
/// | `Dual<T>` | `T.combine` with operands swapped | `T.identity`, when `T: Monoid` |
///
/// ## Example
///
/// ```swift
/// let reversed = sconcat(Dual("a"), [Dual("b"), Dual("c")])
/// reversed.rawValue   // "cba" (instead of the "abc" that String's own Semigroup would give)
///
/// // Using <> (requires CoreFPOperators):
/// let result: Dual<Int.Monoids.Sum> = Dual(.init(1)) <> Dual(.init(2))
/// result.rawValue.rawValue   // 3 (Sum is commutative, so Dual has no visible effect here)
/// ```
///
/// - SeeAlso: ``Semigroup``, ``Monoid``
public struct Dual<T: Semigroup>: Semigroup, RawRepresentable {
    public let rawValue: T

    public init(_ rawValue: T) {
        self.rawValue = rawValue
    }

    public init?(rawValue: T) {
        self.init(rawValue)
    }

    public static func combine(_ lhs: Dual, _ rhs: Dual) -> Dual {
        Dual(T.combine(rhs.rawValue, lhs.rawValue))
    }
}

extension Dual: Monoid where T: Monoid {
    /// The wrapped type's own identity — swapping the operands of `combine(identity, x)` still
    /// yields `x`, so `Dual`'s identity is identical to `T`'s.
    public static var identity: Dual<T> { Dual(T.identity) }
}
