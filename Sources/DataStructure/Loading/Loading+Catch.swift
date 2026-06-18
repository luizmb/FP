// SPDX-License-Identifier: Apache-2.0
import CoreFP
import Foundation

public extension Loading {
    /// Recovers from `.failed` by mapping the error to another `Loading` value.
    /// `.idle`, `.loading`, and `.loaded` are passed through unchanged.
    func `catch`(_ transform: (Failure) -> Loading<Success, Failure>) -> Loading<Success, Failure> {
        switch self {
        case .idle:
            .idle

        case let .loading(prev):
            .loading(previous: prev)

        case let .loaded(value):
            .loaded(value)

        case let .failed(err, _):
            transform(err)
        }
    }
}
