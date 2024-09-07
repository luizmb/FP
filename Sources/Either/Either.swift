import Foundation
import FP

public enum Either<A, B> {
    case left(A)
    case right(B)
}

extension Either: SumType2 {
    public func match<C>(caseLeft: (A) -> C, caseRight: (B) -> C) -> C {
        switch self {
        case let .left(left): caseLeft(left)
        case let .right(right): caseRight(right)
        }
    }
}

extension Either: Equatable where A: Equatable, B: Equatable {}
extension Either: Comparable where A: Comparable, B: Comparable {}
extension Either: Hashable where A: Hashable, B: Hashable {}
extension Either: Decodable where A: Decodable, B: Decodable {}
extension Either: Encodable where A: Encodable, B: Encodable {}
extension Either: Sendable where A: Sendable, B: Sendable {}

@available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
extension Either: Identifiable where A: Identifiable, B: Identifiable, A.ID == B.ID {
    public var id: A.ID {
        match(caseLeft: \.id, caseRight: \.id)
    }
}
