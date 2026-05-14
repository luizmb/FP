extension Bool {
    /// Namespace for `Bool` ``Monoid`` instances.
    ///
    /// Because `Bool` has more than one natural monoid (conjunction, disjunction, XOR),
    /// the instances are provided as named newtypes rather than a direct conformance.
    /// Each wraps a `Bool` and implements the corresponding operation:
    ///
    /// | Type | Operation | Identity |
    /// |------|-----------|---------|
    /// | `Bool.Monoids.And` | `&&` (conjunction) | `true` |
    /// | `Bool.Monoids.Or` | `\|\|` (disjunction) | `false` |
    /// | `Bool.Monoids.Xor` | `!=` (exclusive disjunction) | `false` |
    ///
    /// All three types are `RawRepresentable` with `rawValue: Bool` and also conform to
    /// `ExpressibleByBooleanLiteral` for convenient literal initialisation.
    ///
    /// ## Example
    ///
    /// ```swift
    /// // Fold a sequence of predicates with AND:
    /// let allValid: Bool = mconcat([
    ///     Bool.Monoids.And(isNameValid),
    ///     Bool.Monoids.And(isAgeValid),
    ///     Bool.Monoids.And(isEmailValid),
    /// ]).rawValue
    ///
    /// // Using <> (requires CoreFPOperators):
    /// let result: Bool.Monoids.And = true <> isNameValid <> isAgeValid
    /// ```
    ///
    /// - SeeAlso: ``Monoid``, ``mconcat(_:)``
    public enum Monoids {
        /// Monoid under conjunction (&&), with identity `true`.
        public struct And: Monoid, RawRepresentable {
            public let rawValue: Bool

            public init(_ rawValue: Bool) {
                self.rawValue = rawValue
            }

            public init?(rawValue: Bool) {
                self.init(rawValue)
            }

            public static func combine(_ lhs: And, _ rhs: And) -> And {
                And(lhs.rawValue && rhs.rawValue)
            }

            public static var identity: And { And(true) }
        }

        /// Monoid under disjunction (||), with identity `false`.
        public struct Or: Monoid, RawRepresentable {
            public let rawValue: Bool

            public init(_ rawValue: Bool) {
                self.rawValue = rawValue
            }

            public init?(rawValue: Bool) {
                self.init(rawValue)
            }

            public static func combine(_ lhs: Or, _ rhs: Or) -> Or {
                Or(lhs.rawValue || rhs.rawValue)
            }

            public static var identity: Or { Or(false) }
        }

        /// Monoid under exclusive disjunction (!=), with identity `false`.
        public struct Xor: Monoid, RawRepresentable {
            public let rawValue: Bool

            public init(_ rawValue: Bool) {
                self.rawValue = rawValue
            }

            public init?(rawValue: Bool) {
                self.init(rawValue)
            }

            public static func combine(_ lhs: Xor, _ rhs: Xor) -> Xor {
                Xor(lhs.rawValue != rhs.rawValue)
            }

            public static var identity: Xor { Xor(false) }
        }
    }
}

extension Bool.Monoids.And: ExpressibleByBooleanLiteral {
    public init(booleanLiteral value: Bool) {
        self.rawValue = value
    }
}

extension Bool.Monoids.Or: ExpressibleByBooleanLiteral {
    public init(booleanLiteral value: Bool) {
        self.rawValue = value
    }
}

extension Bool.Monoids.Xor: ExpressibleByBooleanLiteral {
    public init(booleanLiteral value: Bool) {
        self.rawValue = value
    }
}
