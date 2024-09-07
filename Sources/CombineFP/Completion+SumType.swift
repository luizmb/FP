#if canImport(Combine)
import Combine
import Foundation
import FP

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
extension Subscribers.Completion: @retroactive SumType2 {
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
        case .finished: caseLeft(())
        case let .failure(right): caseRight(right)
        }
    }
}

#endif
