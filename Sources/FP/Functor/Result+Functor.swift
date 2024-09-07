import Foundation

public extension Result {
    static func fmap<A0>(
        _ fn: @escaping (A0) -> A
    ) -> (Result<A0, B>) -> Result<A, B> where Self: Sendable {
        { previous in previous.mapLeft(fn) }
    }

    func mapLeft<A1>(
        _ lf: (A) -> A1
    ) -> Result<A1, B> {
        map(lf)
    }

    func mapRight<B1>(
        _ rf: @escaping (B) -> B1
    ) -> Result<A, B1> {
        mapError(rf)
    }

    func bimap<A1, B1>(
        _ lf: @escaping (A) -> A1,
        _ rf: @escaping (B) -> B1
    ) -> Result<A1, B1> {
        map(lf).mapError(rf)
    }
}
