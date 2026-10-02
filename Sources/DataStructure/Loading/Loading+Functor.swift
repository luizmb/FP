// SPDX-License-Identifier: Apache-2.0
import CoreFP
import Foundation

public extension Loading {
    /// Maps the `Success` type, preserving `previous` values in `.loading` and `.failed`.
    /// `(.idle)` and the `Failure` channel pass through unchanged.
    func map<B: Sendable>(_ f: (Success) -> B) -> Loading<B, Failure> {
        switch self {
        case .idle:
            .idle

        case let .loading(prev):
            .loading(previous: prev.map(f))

        case let .loaded(value):
            .loaded(f(value))

        case let .failed(err, prev):
            .failed(error: err, previous: prev.map(f))
        }
    }

    /// Maps the `Failure` type, e.g. a technical `Error` into a user-facing message struct.
    /// The success channel and every `previous` value pass through unchanged.
    func mapError<F2: Sendable>(_ f: (Failure) -> F2) -> Loading<Success, F2> {
        bimap(CoreFP.id, f)
    }

    /// Maps both channels: `f` over every success value (`.loaded` and each `previous`),
    /// `g` over the failure.
    /// bimap :: (a -> b) -> (e -> e') -> Loading e a -> Loading e' b
    func bimap<B: Sendable, F2: Sendable>(_ f: (Success) -> B, _ g: (Failure) -> F2) -> Loading<B, F2> {
        switch self {
        case .idle:
            .idle

        case let .loading(prev):
            .loading(previous: prev.map(f))

        case let .loaded(value):
            .loaded(f(value))

        case let .failed(err, prev):
            .failed(error: g(err), previous: prev.map(f))
        }
    }

    /// Curried form for point-free style.
    /// (<$>) :: Functor f => (a -> b) -> f a -> f b
    static func fmap<B: Sendable>(_ f: @escaping @Sendable (Success) -> B) -> @Sendable (Loading<Success, Failure>) -> Loading<B, Failure> {
        { $0.map(f) }
    }
}
