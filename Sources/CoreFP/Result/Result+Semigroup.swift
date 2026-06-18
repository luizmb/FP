// SPDX-License-Identifier: Apache-2.0
extension Result {
    /// Namespace for `Result` ``Semigroup`` and ``Monoid`` instances.
    ///
    /// Because `Result` can express multiple reasonable combining strategies,
    /// the instances are provided as named newtypes rather than direct conformances.
    ///
    /// | Type | Win | Combining failures | Combining successes | Identity |
    /// |------|-----|-------------------|---------------------|---------|
    /// | `Optimistic` | `.success` | left wins | via `Success: Semigroup` | — (Semigroup only) |
    /// | `OptimisticCombining` | `.success` | via `Failure: Semigroup` | via `Success: Semigroup` | `.failure(Failure.identity)` |
    /// | `Pessimistic` | `.failure` | via `Failure: Semigroup` | left wins | — (Semigroup only) |
    /// | `PessimisticCombining` | `.failure` | via `Failure: Semigroup` | via `Success: Semigroup` | `.success(Success.identity)` |
    ///
    /// ## Usage
    ///
    /// ```swift
    /// // Optimistic: success beats failure, combine successes
    /// let combined = Result<[Int], Error>.Monoids.Optimistic.combine(
    ///     .init(.success([1, 2])),
    ///     .init(.success([3, 4]))
    /// )
    /// combined.rawValue   // .success([1, 2, 3, 4])
    /// ```
    ///
    /// - SeeAlso: ``Semigroup``, ``Monoid``
    public enum Monoids {
        /// Semigroup: success wins over failure; combines two successes;
        /// picks the left for two failures (Failure need not be Semigroup).
        public struct Optimistic: RawRepresentable {
            public let rawValue: Result
            public init(_ rawValue: Result) { self.rawValue = rawValue }
            public init?(rawValue: Result) { self.init(rawValue) }
        }

        /// Monoid: success wins over failure; combines both sides when present;
        /// identity is `.failure(Failure.identity)`.
        public struct OptimisticCombining: RawRepresentable {
            public let rawValue: Result
            public init(_ rawValue: Result) { self.rawValue = rawValue }
            public init?(rawValue: Result) { self.init(rawValue) }
        }

        /// Semigroup: failure wins over success; combines two failures;
        /// picks the left for two successes (Success need not be Semigroup).
        public struct Pessimistic: RawRepresentable {
            public let rawValue: Result
            public init(_ rawValue: Result) { self.rawValue = rawValue }
            public init?(rawValue: Result) { self.init(rawValue) }
        }

        /// Monoid: failure wins over success; combines both sides when present;
        /// identity is `.success(Success.identity)`.
        public struct PessimisticCombining: RawRepresentable {
            public let rawValue: Result
            public init(_ rawValue: Result) { self.rawValue = rawValue }
            public init?(rawValue: Result) { self.init(rawValue) }
        }
    }
}

// MARK: - Semigroup conformances

extension Result.Monoids.Optimistic: Sendable where Success: Sendable, Failure: Sendable {}

extension Result.Monoids.Optimistic: Semigroup where Success: Semigroup, Failure: Sendable {
    public static func combine(_ lhs: Self, _ rhs: Self) -> Self {
        switch (lhs.rawValue, rhs.rawValue) {
        case let (.success(a), .success(b)):
            Self(.success(Success.combine(a, b)))

        case (.success, .failure):
            lhs

        case (.failure, .success):
            rhs

        case (.failure, .failure):
            lhs
        }
    }
}

extension Result.Monoids.OptimisticCombining: Sendable where Success: Sendable, Failure: Sendable {}

extension Result.Monoids.OptimisticCombining: Semigroup where Success: Semigroup, Failure: Semigroup {
    public static func combine(_ lhs: Self, _ rhs: Self) -> Self {
        switch (lhs.rawValue, rhs.rawValue) {
        case let (.success(a), .success(b)):
            Self(.success(Success.combine(a, b)))

        case (.success, .failure):
            lhs

        case (.failure, .success):
            rhs

        case let (.failure(e1), .failure(e2)):
            Self(.failure(Failure.combine(e1, e2)))
        }
    }
}

extension Result.Monoids.Pessimistic: Sendable where Success: Sendable, Failure: Sendable {}

extension Result.Monoids.Pessimistic: Semigroup where Failure: Semigroup {
    public static func combine(_ lhs: Self, _ rhs: Self) -> Self {
        switch (lhs.rawValue, rhs.rawValue) {
        case (.success, .failure):
            rhs

        case (.failure, .success):
            lhs

        case let (.failure(e1), .failure(e2)):
            Self(.failure(Failure.combine(e1, e2)))

        case (.success, .success):
            lhs
        }
    }
}

extension Result.Monoids.PessimisticCombining: Sendable where Success: Sendable, Failure: Sendable {}

extension Result.Monoids.PessimisticCombining: Semigroup where Success: Semigroup, Failure: Semigroup {
    public static func combine(_ lhs: Self, _ rhs: Self) -> Self {
        switch (lhs.rawValue, rhs.rawValue) {
        case (.success, .failure):
            rhs

        case (.failure, .success):
            lhs

        case let (.failure(e1), .failure(e2)):
            Self(.failure(Failure.combine(e1, e2)))

        case let (.success(a), .success(b)):
            Self(.success(Success.combine(a, b)))
        }
    }
}

// MARK: - Monoid conformances

extension Result.Monoids.OptimisticCombining: Monoid where Success: Semigroup, Failure: Monoid {
    public static var identity: Self { Self(.failure(Failure.identity)) }
}

extension Result.Monoids.PessimisticCombining: Monoid where Success: Monoid, Failure: Semigroup {
    public static var identity: Self { Self(.success(Success.identity)) }
}
