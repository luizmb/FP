// SPDX-License-Identifier: Apache-2.0
import CoreFP
import Foundation

// Result-interop and state-machine transitions for Loading.

public extension Loading {
    /// Transitions to `.loading`, carrying the current `loadedOrPrevious` value.
    func startLoading() -> Self {
        .loading(previous: loadedOrPrevious)
    }

    /// Applies a `Result` to transition to `.loaded` or `.failed`, preserving
    /// `loadedOrPrevious` as the previous value on failure.
    func applying(_ result: Result<Success, Failure>) -> Self {
        switch result {
        case let .success(value):
            .loaded(value)

        case let .failure(error):
            .failed(error: error, previous: loadedOrPrevious)
        }
    }

    /// Wraps a `Result` as a fresh `Loading` with no prior context.
    static func from(_ result: Result<Success, Failure>) -> Self {
        switch result {
        case let .success(value):
            .loaded(value)

        case let .failure(error):
            .failed(error: error, previous: nil)
        }
    }
}
