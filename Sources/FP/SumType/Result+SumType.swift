import Foundation

extension Result: SumType2 {
    public typealias A = Success
    public typealias B = Failure

    public static func left(_ a: Success) -> Result<Success, Failure> {
        .success(a)
    }

    public static func right(_ b: Failure) -> Result<Success, Failure> {
        .failure(b)
    }

    public func match<C>(caseLeft: (Success) -> C, caseRight: (Failure) -> C) -> C {
        switch self {
        case let .success(value): caseLeft(value)
        case let .failure(value): caseRight(value)
        }
    }
}
