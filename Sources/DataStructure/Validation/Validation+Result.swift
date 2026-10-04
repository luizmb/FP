// SPDX-License-Identifier: Apache-2.0
import CoreFP

public extension Validation {
    /// Convert to Result — requires E: Error.
    func toResult() -> Result<A, E> where E: Error {
        match(caseFailure: Result.failure, caseSuccess: Result.success)
    }
}

public extension Validation where E: Error {
    /// Convert from Result — requires E: Semigroup & Error.
    ///
    /// ```swift
    /// Validation(Result<Int, Errors>.success(42))  // .success(42)
    /// ```
    init(_ result: Result<A, E>) {
        switch result {
        case let .failure(e):
            self = .failure(e)

        case let .success(a):
            self = .success(a)
        }
    }
}
