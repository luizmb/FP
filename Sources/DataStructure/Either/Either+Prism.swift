import CoreFP
import Foundation

// Hand-written equivalent of what FP's `@Prisms` macro would generate for `Either`.
//
// Because `Either<A, B>` is generic, Swift forbids `static let` in its scope, so the
// static `prism` accessor is a computed `static var` returning a fresh `Prisms()` per
// access — matching what the macro emits for any generic host.
//
// `@dynamicMemberLookup` lives on the `Either` declaration in `Either.swift`; the
// subscript here lights up `either.left` / `either.right` accessors through a single
// keypath-driven subscript rather than per-case computed properties.

public extension Either {
    struct Prisms: Sendable {
        public let left: CoreFP.Prism<Either, A> = CoreFP.prism(
            preview: { (s: Either) in guard case .left(let a) = s else { return nil }; return a },
            review: Either.left
        )
        public let right: CoreFP.Prism<Either, B> = CoreFP.prism(
            preview: { (s: Either) in guard case .right(let b) = s else { return nil }; return b },
            review: Either.right
        )
    }

    static var prism: Prisms { Prisms() }

    subscript<PrismFocus>(
        dynamicMember keyPath: KeyPath<Prisms, CoreFP.Prism<Either, PrismFocus>>
    ) -> PrismFocus? {
        Self.prism[keyPath: keyPath].preview(self)
    }

    enum cases: CoreFP.CaseMatchable { // swiftlint:disable:this type_name
        public typealias Subject = Either
        case left, right

        public func matches(_ value: Either) -> Bool {
            switch (self, value) {
            case (.left, .left):   true
            case (.right, .right): true
            default:               false
            }
        }
    }

    func `is`(_ c: cases) -> Bool { c.matches(self) }
}

extension Either: CoreFP.HasCases {
    public typealias Cases = cases
}
