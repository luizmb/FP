import CoreFP
import Foundation

public extension Loading {
    /// Maps the `Success` type, preserving `previous` values in `.loading` and `.failed`.
    /// `(.idle)` and the `Failure` channel pass through unchanged.
    func map<B: Sendable>(_ f: (Success) -> B) -> Loading<B, Failure> {
        switch self {
        case .idle:                    .idle
        case .loading(let prev):       .loading(previous: prev.map(f))
        case .loaded(let value):       .loaded(f(value))
        case let .failed(err, prev):   .failed(error: err, previous: prev.map(f))
        }
    }

    /// Curried form for point-free style.
    /// (<$>) :: Functor f => (a -> b) -> f a -> f b
    static func fmap<B: Sendable>(_ f: @escaping (Success) -> B) -> (Loading<Success, Failure>) -> Loading<B, Failure> {
        { $0.map(f) }
    }
}
