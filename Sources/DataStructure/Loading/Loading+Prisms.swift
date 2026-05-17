import CoreFP
import Foundation

// Hand-written equivalent of what FP's `@Prisms` macro would generate for `Loading`.
//
// Because `Loading` is generic, Swift forbids `static let` in its scope, so the static
// `prism` accessor is a computed `static var` returning a fresh `Prisms()` per access —
// matching what the macro emits for any generic host. The dynamic-member subscript is
// present so `loading.idle`, `loading.loaded`, etc. resolve through a single subscript
// rather than per-case computed properties.

public extension Loading {
    struct Prisms: Sendable {
        public let idle: CoreFP.Prism<Loading, Void> = CoreFP.prism(
            preview: { (s: Loading) in guard case .idle = s else { return nil }; return () },
            review: { (_: Void) in Loading.idle }
        )
        public let loading: CoreFP.Prism<Loading, Success?> = CoreFP.prism(
            preview: { (s: Loading) in guard case .loading(let a) = s else { return nil }; return a },
            review: Loading.loading
        )
        public let loaded: CoreFP.Prism<Loading, Success> = CoreFP.prism(
            preview: { (s: Loading) in guard case .loaded(let a) = s else { return nil }; return a },
            review: Loading.loaded
        )
        public let failed: CoreFP.Prism<Loading, (Failure, Success?)> = CoreFP.prism(
            preview: { (s: Loading) in guard case .failed(let v0, let v1) = s else { return nil }; return (v0, v1) },
            review: { (t: (Failure, Success?)) in Loading.failed(error: t.0, previous: t.1) }
        )
    }

    static var prism: Prisms { Prisms() }

    subscript<PrismFocus>(
        dynamicMember keyPath: KeyPath<Prisms, CoreFP.Prism<Loading, PrismFocus>>
    ) -> PrismFocus? {
        Self.prism[keyPath: keyPath].preview(self)
    }

    enum Cases: CoreFP.CaseMatchable {
        public typealias Subject = Loading
        case idle, loading, loaded, failed

        public func matches(_ value: Loading) -> Bool {
            switch (self, value) {
            case (.idle, .idle):       true
            case (.loading, .loading): true
            case (.loaded, .loaded):   true
            case (.failed, .failed):   true
            default:                   false
            }
        }
    }

    func `is`(_ c: Cases) -> Bool { c.matches(self) }
}

extension Loading: CoreFP.HasCases {}
