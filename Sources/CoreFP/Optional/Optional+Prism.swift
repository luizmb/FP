import Foundation

// Hand-written equivalent of what FP's `@Prisms` macro would generate for `Optional`.
//
// `Optional<Wrapped>` is generic, so the static `prism` accessor is a computed
// `static var` returning a fresh `Prisms()` per access.
//
// `Prismatic` conformance unlocks `\.case` key paths; payload extraction goes through the
// prism (`Optional.prism.some.preview(x)`) or `\.some`.

public extension Optional {
    struct Prisms: Sendable {
        public let some: CoreFP.Prism<Wrapped?, Wrapped> = CoreFP.prism(
            preview: { (s: Wrapped?) in s },
            review: Optional.some
        )
        public let none: CoreFP.Prism<Wrapped?, Void> = CoreFP.prism(
            preview: { (s: Wrapped?) in if case .none = s { return () } else { return nil } },
            review: { (_: Void) in .none }
        )
    }

    static var prism: Prisms { Prisms() }

    enum Cases: CoreFP.CaseMatchable {
        public typealias Subject = Wrapped?
        case some, none

        public func matches(_ value: Wrapped?) -> Bool {
            switch (self, value) {
            case (.some, .some): true
            case (.none, .none): true
            default:             false
            }
        }
    }

    func `is`(_ c: Cases) -> Bool { c.matches(self) }
}

extension Optional: CoreFP.HasCases {}
extension Optional: CoreFP.Prismatic {}
