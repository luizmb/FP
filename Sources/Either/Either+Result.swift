import Foundation
import FP

public extension Either {
    func result() -> Result<B, A> where A: Error {
        Result.from(self.inverted())
    }
}


public extension Result {
    var either: SumTypeCopyStrategy<Either<Success, Failure>, Either<Failure, Success>> {
        .init(
            parallel: { Either.from(self) },
            crossover: { Either.from(self).inverted() }
        )
    }
}
