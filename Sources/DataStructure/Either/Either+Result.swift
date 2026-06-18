// SPDX-License-Identifier: Apache-2.0
import CoreFP
import Foundation

public extension Either {
    /// Converts `Either<A, B>` to `Result<B, A>` when `A: Error`.
    ///
    /// The left case maps to `.failure` and the right case maps to `.success`:
    ///
    /// ```swift
    /// Either<DBError, User>.left(DBError.notFound).result()    // .failure(.notFound)
    /// Either<DBError, User>.right(user).result()              // .success(user)
    /// ```
    func result() -> Result<B, A> where A: Error {
        Result.from(self.inverted())
    }
}

public extension Result where Success: Sendable, Failure: Sendable {
    /// Returns a ``SumTypeCopyStrategy`` for converting to `Either`.
    ///
    /// `either.parallel()` produces `Either<Success, Failure>` (success is left).
    /// `either.crossover()` produces `Either<Failure, Success>` (success is right — standard).
    ///
    /// ```swift
    /// let strategy = result.either
    /// let eitherSuccessLeft = strategy.parallel()    // Either<Success, Failure>
    /// let eitherSuccessRight = strategy.crossover()  // Either<Failure, Success>
    /// ```
    var either: SumTypeCopyStrategy<Either<Success, Failure>, Either<Failure, Success>> {
        .init(
            parallel: { Either.from(self) },
            crossover: { Either.from(self).inverted() }
        )
    }
}
