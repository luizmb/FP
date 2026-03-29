extension Bool {
    /// Namespace for Bool Monoid instances.
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
    }
}
