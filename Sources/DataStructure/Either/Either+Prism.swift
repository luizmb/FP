// SPDX-License-Identifier: Apache-2.0
import CoreFP
import Foundation

// Hand-written equivalent of what FP's `@Prisms` macro would generate for `Either`.
//
// Because `Either<A, B>` is generic, Swift forbids `static let` in its scope, so the
// static `prism` accessor is a computed `static var` returning a fresh `Prisms()` per
// access — matching what the macro emits for any generic host.
//
// `Prismatic` conformance unlocks `\.case` key paths; payload extraction goes through the
// prism (`Either.prism.left.preview(x)`), `\.left`, or the plain `either.left` property.

public extension Either {
    struct Prisms: Sendable {
        public let left: CoreFP.Prism<Either, A> = CoreFP.prism(
            preview: { (s: Either) in guard case let .left(a) = s else { return nil }; return a },
            review: Either.left
        )
        public let right: CoreFP.Prism<Either, B> = CoreFP.prism(
            preview: { (s: Either) in guard case let .right(b) = s else { return nil }; return b },
            review: Either.right
        )
    }

    /// The `prism` property.
    static var prism: Prisms { Prisms() }

    /// The left payload, or `nil` if `self` is `.right`. Delegates to `Self.prism.left`.
    var left: A? { Self.prism.left.preview(self) }
    /// The right payload, or `nil` if `self` is `.left`. Delegates to `Self.prism.right`.
    var right: B? { Self.prism.right.preview(self) }

    enum Cases: CoreFP.CaseMatchable {
        public typealias Subject = Either
        case left, right

        public func matches(_ value: Either) -> Bool {
            switch (self, value) {
            case (.left, .left):
                true

            case (.right, .right):
                true

            default:
                false
            }
        }
    }

    /// Declaration.
    func `is`(_ c: Cases) -> Bool { c.matches(self) }
}

extension Either: CoreFP.HasCases {}
extension Either: CoreFP.Prismatic {}
