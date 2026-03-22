import CoreFP

public extension Validation {
    /// Convert to Result — requires E: Error.
    func toResult() -> Result<A, E> where E: Error {
        match(caseFailure: Result.failure, caseSuccess: Result.success)
    }
}

/// Convert from Result to Validation — requires E: Semigroup & Error.
public func validationFromResult<E: Semigroup & Error, A>(_ result: Result<A, E>) -> Validation<E, A> {
    switch result {
    case let .failure(e): .failure(e)
    case let .success(a): .success(a)
    }
}
