import CoreFP

// Hand-written equivalent of what FP's `@Prisms` macro would generate for `Validation`.
//
// Because `Validation<E, A>` is generic, Swift forbids `static let` in its scope, so the
// static `prism` accessor is a computed `static var` returning a fresh `Prisms()` per
// access — matching what the macro emits for any generic host.
//
// `@dynamicMemberLookup` lives on the `Validation` declaration in `Validation.swift`;
// the subscript here lights up `validation.failure` / `validation.success` accessors
// through a single keypath-driven subscript rather than per-case computed properties.

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

    static var prism: Prisms { Prisms() }

    subscript<PrismFocus>(
        dynamicMember keyPath: KeyPath<Prisms, CoreFP.Prism<Validation, PrismFocus>>
    ) -> PrismFocus? {
        Self.prism[keyPath: keyPath].preview(self)
    }

    enum cases: CoreFP.CaseMatchable { // swiftlint:disable:this type_name
        public typealias Subject = Validation
        case failure, success

        public func matches(_ value: Validation) -> Bool {
            switch (self, value) {
            case (.failure, .failure): true
            case (.success, .success): true
            default:                   false
            }
        }
    }

    func `is`(_ c: cases) -> Bool { c.matches(self) }
}

extension Validation: CoreFP.HasCases {
    public typealias Cases = cases
}
