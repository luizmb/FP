import Foundation

public extension Result {
    static func fmap<A1>(
        _ fn: @escaping @Sendable (A) -> A1
    ) -> @Sendable (Result<A, B>) -> Result<A1, B> {
        { $0.mapLeft(fn) }
    }

    func mapLeft<A1>(
        _ lf: (A) -> A1
    ) -> Result<A1, B> {
        map(lf)
    }

    func mapRight<B1>(
        _ rf: @escaping @Sendable (B) -> B1
    ) -> Result<A, B1> {
        mapError(rf)
    }

    func bimap<A1, B1>(
        _ lf: @escaping @Sendable (A) -> A1,
        _ rf: @escaping @Sendable (B) -> B1
    ) -> Result<A1, B1> {
        map(lf).mapError(rf)
    }

    static func bimap<A1, B1>(
        _ lf: @escaping @Sendable (A) -> A1,
        _ rf: @escaping @Sendable (B) -> B1
    ) -> (Result<A, B>) -> Result<A1, B1> {
        { $0.bimap(lf, rf) }
    }
}
