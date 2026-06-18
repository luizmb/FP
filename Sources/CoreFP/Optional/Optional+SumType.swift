// SPDX-License-Identifier: Apache-2.0
import Foundation

// MARK: - Optional as SumType2

//
// Optional<A> is isomorphic to Either<A, Void>:
//   .some(a) ≅ .left(a)    (SumType2.A = Wrapped)
//   .none    ≅ .right(())  (SumType2.B = Void)
//
// This conformance enables Optional to participate in generic SumType2 APIs
// and provides the uniform `match` eliminator as an alternative to `if let`.

extension Optional: SumType2 {
    public typealias A = Wrapped
    public typealias B = Void

    public static func left(_ a: Wrapped) -> Wrapped? {
        .some(a)
    }

    public static func right(_: Void) -> Wrapped? {
        .none
    }

    public func match<C>(caseLeft: (Wrapped) -> C, caseRight: (()) -> C) -> C {
        switch self {
        case let value?:
            caseLeft(value)

        case nil:
            caseRight(())
        }
    }
}
