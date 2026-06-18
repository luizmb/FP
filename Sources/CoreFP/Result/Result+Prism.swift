// SPDX-License-Identifier: Apache-2.0
import Foundation

// Hand-written equivalent of what FP's `@Prisms` macro would generate for `Result`.
//
// `Result<Success, Failure>` is generic, so the static `prism` accessor is a computed
// `static var` returning a fresh `Prisms()` per access.
//
// `Prismatic` conformance unlocks `\.case` key paths; payload extraction goes through the
// prism (`Result.prism.success.preview(x)`) or `\.success`.

public extension Result {
    struct Prisms: Sendable {
        public let success: CoreFP.Prism<Result, Success> = CoreFP.prism(
            preview: { (s: Result) in if case .success(let v) = s { v } else { nil } },
            review: Result.success
        )
        public let failure: CoreFP.Prism<Result, Failure> = CoreFP.prism(
            preview: { (s: Result) in if case .failure(let e) = s { e } else { nil } },
            review: Result.failure
        )
    }

    /// The `prism` property.
    static var prism: Prisms { Prisms() }

    enum Cases: CoreFP.CaseMatchable {
        public typealias Subject = Result
        case success, failure

        public func matches(_ value: Result) -> Bool {
            switch (self, value) {
            case (.success, .success):
                true

            case (.failure, .failure):
                true

            default:
                false
            }
        }
    }

    /// Declaration.
    func `is`(_ c: Cases) -> Bool { c.matches(self) }
}

extension Result: CoreFP.HasCases {}
extension Result: CoreFP.Prismatic {}
