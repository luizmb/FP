// SPDX-License-Identifier: Apache-2.0
#if canImport(Combine)
import Combine
import Foundation

// MARK: - Subscribers.Completion as SumType2
//
// Subscribers.Completion<Failure> is structurally a SumType2:
//   .finished     ≅ .left(())   (SumType2.A = Void)
//   .failure(e)   ≅ .right(e)   (SumType2.B = Failure)
//
// This conformance lets Completion participate in generic SumType2 APIs
// and provides a uniform `match` eliminator.

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
extension Subscribers.Completion: SumType2 {
    public typealias A = Void
    public typealias B = Failure

    public static func left(_ a: A) -> Self {
        .finished
    }

    public static func right(_ b: B) -> Self {
        .failure(b)
    }

    public func match<C>(caseLeft: (A) -> C, caseRight: (B) -> C) -> C {
        switch self {
        case .finished:
            caseLeft(())

        case let .failure(right):
            caseRight(right)
        }
    }
}

#endif
