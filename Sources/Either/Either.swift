import Foundation

public enum Either<T, U> {
    case left(T)
    case right(U)
}

public extension Either {
    init(left: T) {
        self = .left(left)
    }

    init(right: U) {
        self = .right(right)
    }
}

extension Either: Equatable where T: Equatable, U: Equatable {}
extension Either: Comparable where T: Comparable, U: Comparable {}
extension Either: Hashable where T: Hashable, U: Hashable {}
extension Either: Decodable where T: Decodable, U: Decodable {}
extension Either: Encodable where T: Encodable, U: Encodable {}

@available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
extension Either: Identifiable where T: Identifiable, U: Identifiable, T.ID == U.ID {
    public var id: T.ID {
        switch self {
        case let .left(value): value.id
        case let .right(value): value.id
        }
    }
}
