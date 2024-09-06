import Foundation

public extension Either {
    func result() -> Result<U, T> where T: Error {
        switch self {
        case let .left(error): .failure(error)
        case let .right(success): .success(success)
        }
    }
}

public extension Result {
    func either() -> Either<Failure, Success> {
        switch self {
        case let .success(right): .right(right)
        case let .failure(left): .left(left)
        }
    }
}
