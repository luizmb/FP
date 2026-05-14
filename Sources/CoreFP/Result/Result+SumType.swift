import Foundation

// MARK: - Result as SumType2
//
// Result<Success, Failure> is isomorphic to Either<Success, Failure>:
//   .success(a) ≅ .left(a)   (SumType2.A = Success)
//   .failure(e) ≅ .right(e)  (SumType2.B = Failure)
//
// This conformance enables Result to participate in generic SumType2 APIs
// and provides the uniform `match` eliminator as an alternative to switch.

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
