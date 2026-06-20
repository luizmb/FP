// SPDX-License-Identifier: Apache-2.0
import CoreFP
import Foundation

public extension Loading {
    /// Combines two `Loading` values sharing a `Failure` type into a `Loading` of the pair.
    ///
    /// Precedence — first match wins:
    /// 1. If either side is `.failed`, the result is `.failed` carrying the first error
    ///    encountered and a pair of `loadedOrPrevious` values when both sides have one.
    /// 2. If either side is `.idle`, the result is `.idle`.
    /// 3. If either side is `.loading`, the result is `.loading`, with `previous` set to the
    ///    pair of `loadedOrPrevious` values when both sides have one.
    /// 4. Otherwise both sides are `.loaded` and the result is `.loaded` with the pair.
    static func zip<Left: Sendable, Right: Sendable>(
        _ left: Loading<Left, Failure>,
        _ right: Loading<Right, Failure>
    ) -> Loading<(Left, Right), Failure>
    where Success == (Left, Right) {
        switch (left, right) {
        case let (.failed(err, _), _),
             let (_, .failed(err, _)):
            .failed(error: err, previous: (Left, Right)?.zip(left.loadedOrPrevious, right.loadedOrPrevious))

        case (.idle, _),
             (_, .idle):
            .idle

        case let (.loading(l), _):
            .loading(previous: (Left, Right)?.zip(l, right.loadedOrPrevious))

        case let (_, .loading(r)):
            .loading(previous: (Left, Right)?.zip(left.loadedOrPrevious, r))

        case let (.loaded(l), .loaded(r)):
            .loaded((l, r))
        }
    }
}
