import CoreFP
import Foundation

public extension Loading {
    /// Recovers from `.failed` by mapping the error to another `Loading` value.
    /// `.idle`, `.loading`, and `.loaded` are passed through unchanged.
    func `catch`(_ transform: (Failure) -> Loading<Success, Failure>) -> Loading<Success, Failure> {
        switch self {
        case .idle:                  .idle
        case .loading(let prev):     .loading(previous: prev)
        case .loaded(let value):     .loaded(value)
        case .failed(let err, _):    transform(err)
        }
    }
}
