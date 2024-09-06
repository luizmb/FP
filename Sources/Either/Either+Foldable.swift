import Foundation

public extension Either {
    func bifoldMap<Z>(
        leftBy lf: (T) -> Z,
        rightBy rf: (U) -> Z
    ) -> Z {
        switch self {
        case let .left(left):
            return lf(left)
        case let .right(right):
            return rf(right)
        }
    }

    func fromLeft(_ otherwise: T) -> T {
        left ?? otherwise
    }

    func fromRight(_ otherwise: U) -> U {
        right ?? otherwise
    }
}
