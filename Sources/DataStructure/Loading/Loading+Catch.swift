// SPDX-License-Identifier: Apache-2.0
import CoreFP
import Foundation

public extension Loading {
    /// Recovers from `.failed` by mapping the error (and the stale `previous` value, so the
    /// handler can keep showing it) to another `Loading`, possibly with a different failure
    /// type, like Haskell's `catchE`. `.idle`, `.loading`, and `.loaded` pass through unchanged.
    ///
    /// ```swift
    /// state.catch { error, previous in .loading(previous: previous) }   // retry, keep stale data
    /// ```
    func `catch`<F2: Sendable>(_ transform: (Failure, Success?) -> Loading<Success, F2>) -> Loading<Success, F2> {
        switch self {
        case .idle:
            .idle

        case let .loading(prev):
            .loading(previous: prev)

        case let .loaded(value):
            .loaded(value)

        case let .failed(err, prev):
            transform(err, prev)
        }
    }
}
