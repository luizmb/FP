// SPDX-License-Identifier: Apache-2.0
import CoreFP

// Hand-written equivalent of what FP's `@Prisms` macro would generate for `Validation`.
//
// Because `Validation<E, A>` is generic, Swift forbids `static let` in its scope, so the
// static `prism` accessor is a computed `static var` returning a fresh `Prisms()` per
// access — matching what the macro emits for any generic host.
//
// `Prismatic` conformance unlocks `\.case` key paths; payload extraction goes through the
// prism (`Validation.prism.success.preview(x)`) or `\.success`.

public extension Validation {
    struct Prisms: Sendable {
        public let failure: CoreFP.Prism<Validation, E> = CoreFP.prism(
            preview: { (s: Validation) in guard case .failure(let e) = s else { return nil }; return e },
            review: Validation.failure
        )
        public let success: CoreFP.Prism<Validation, A> = CoreFP.prism(
            preview: { (s: Validation) in guard case .success(let a) = s else { return nil }; return a },
            review: Validation.success
        )
    }

    /// The `prism` property.
    static var prism: Prisms { Prisms() }

    enum Cases: CoreFP.CaseMatchable {
        public typealias Subject = Validation
        case failure, success

        public func matches(_ value: Validation) -> Bool {
            switch (self, value) {
            case (.failure, .failure):
                true

            case (.success, .success):
                true

            default:
                false
            }
        }
    }

    /// Declaration.
    func `is`(_ c: Cases) -> Bool { c.matches(self) }
}

extension Validation: CoreFP.HasCases {}
extension Validation: CoreFP.Prismatic {}
