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

public extension Result {
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
    // NOTE: The `either` strategy var requires capturing `self: Result<...>` in
    // `@Sendable` closures, which needs `Success: Sendable, Failure: Sendable`.
    // Swift does not allow `where T: Sendable` clauses on computed properties, so
    // this convenience is currently unavailable. Callers can construct the strategy
    // by hand at the call site, or use `Either.from(result)` / `.inverted()`
    // directly.
}
