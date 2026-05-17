import CoreFP
import Foundation

// Hand-written equivalent of what FP's `@Prisms` macro would generate for `Loading`.
//
// The macro itself can't be applied here because Loading is a generic type and Swift forbids
// `static let` stored properties in generic contexts. We use `static var` (computed) so the
// surface is identical for callers; the only structural difference is the storage strategy.

public extension Loading {
    enum prism { // swiftlint:disable:this type_name
        public static var idle: CoreFP.Prism<Loading, Void> {
            CoreFP.prism(
                preview: { (s: Loading) in guard case .idle = s else { return nil }; return () },
                review: { (_: Void) in Loading.idle }
            )
        }

        public static var loading: CoreFP.Prism<Loading, Success?> {
            CoreFP.prism(
                preview: { (s: Loading) in guard case .loading(let a) = s else { return nil }; return a },
                review: Loading.loading
            )
        }

        public static var loaded: CoreFP.Prism<Loading, Success> {
            CoreFP.prism(
                preview: { (s: Loading) in guard case .loaded(let a) = s else { return nil }; return a },
                review: Loading.loaded
            )
        }

        public static var failed: CoreFP.Prism<Loading, (Failure, Success?)> {
            CoreFP.prism(
                preview: { (s: Loading) in guard case .failed(let v0, let v1) = s else { return nil }; return (v0, v1) },
                review: { (t: (Failure, Success?)) in Loading.failed(error: t.0, previous: t.1) }
            )
        }
    }

    var idle: Void? { Self.prism.idle.preview(self) }
    var loading: Success?? { Self.prism.loading.preview(self) }
    var loaded: Success? { Self.prism.loaded.preview(self) }
    var failed: (Failure, Success?)? { Self.prism.failed.preview(self) }

    enum cases: CaseIterable { // swiftlint:disable:this type_name
        case idle, loading, loaded, failed

        public func matches(_ value: Loading) -> Bool {
            switch (self, value) {
            case (.idle, .idle):       return true
            case (.loading, .loading): return true
            case (.loaded, .loaded):   return true
            case (.failed, .failed):   return true
            default:                   return false
            }
        }
    }

    func `is`(_ c: cases) -> Bool { c.matches(self) }
}
