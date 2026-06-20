// SPDX-License-Identifier: Apache-2.0
import CoreFP
import Foundation

// Hand-written equivalent of what FP's `@Prisms` macro would generate for `Loading`.
//
// Because `Loading` is generic, Swift forbids `static let` in its scope, so the static
// `prism` accessor is a computed `static var` returning a fresh `Prisms()` per access —
// matching what the macro emits for any generic host. `Prismatic` conformance unlocks
// `\.case` key paths; payload extraction goes through the prism or `\.case`.

public extension Loading {
    struct Prisms: Sendable {
        public let idle: CoreFP.Prism<Loading, Void> = CoreFP.prism(
            preview: { (s: Loading) in guard case .idle = s else { return nil }; return () },
            review: { (_: Void) in Loading.idle }
        )
        public let loading: CoreFP.Prism<Loading, Success?> = CoreFP.prism(
            preview: { (s: Loading) in guard case let .loading(a) = s else { return nil }; return a },
            review: Loading.loading
        )
        public let loaded: CoreFP.Prism<Loading, Success> = CoreFP.prism(
            preview: { (s: Loading) in guard case let .loaded(a) = s else { return nil }; return a },
            review: Loading.loaded
        )
        public let failed: CoreFP.Prism<Loading, (Failure, Success?)> = CoreFP.prism(
            preview: { (s: Loading) in guard case let .failed(v0, v1) = s else { return nil }; return (v0, v1) },
            review: { (t: (Failure, Success?)) in Loading.failed(error: t.0, previous: t.1) }
        )
    }

    /// The `prism` property.
    static var prism: Prisms { Prisms() }

    enum Cases: CoreFP.CaseMatchable {
        public typealias Subject = Loading
        case idle, loading, loaded, failed

        public func matches(_ value: Loading) -> Bool {
            switch (self, value) {
            case (.idle, .idle):
                true

            case (.loading, .loading):
                true

            case (.loaded, .loaded):
                true

            case (.failed, .failed):
                true

            default:
                false
            }
        }
    }

    /// Declaration.
    func `is`(_ c: Cases) -> Bool { c.matches(self) }
}

extension Loading: CoreFP.HasCases {}
extension Loading: CoreFP.Prismatic {}
