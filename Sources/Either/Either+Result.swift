import Foundation

public extension Either {
    func result() -> Result<B, A> where A: Error {
        Result.from(self.inverted())
    }
}

public struct ResultEitherBridge<Success, Failure> {
    public let parallel: () -> Either<Success, Failure>
    public let crossover: () -> Either<Failure, Success>

    public func callAsFunction() -> Either<Failure, Success> { 
        crossover()
    }
}

public extension Result {
    var either: ResultEitherBridge<Success, Failure> {
        .init(
            parallel: { Either.from(self) },
            crossover: { Either.from(self).inverted() }
        )
    }
}
