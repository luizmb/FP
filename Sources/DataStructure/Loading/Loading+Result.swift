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
        case .success(let value):    .loaded(value)
        case .failure(let error):    .failed(error, previous: loadedOrPrevious)
        }
    }

    /// Wraps a `Result` as a fresh `Loading` with no prior context.
    static func from(_ result: Result<Success, Failure>) -> Self {
        switch result {
        case .success(let value):    .loaded(value)
        case .failure(let error):    .failed(error, previous: nil)
        }
    }
}
