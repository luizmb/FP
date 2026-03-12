import Foundation
import FP

public extension Either {
    static func fmap<B1>(
        _ fn: @escaping (B) -> B1
    ) -> (Either<A, B>) -> Either<A, B1> where Self: Sendable {
        { $0.mapRight(fn) }
    }

    func mapLeft<A1>(
        _ lf: @escaping (A) -> A1
    ) -> Either<A1, B> {
        match(
            caseLeft: compose(lf, Either<A1, B>.left),
            caseRight: Either<A1, B>.right
        )
    }

    func mapRight<B1>(
        _ rf: @escaping (B) -> B1
    ) -> Either<A, B1> {
        match(
            caseLeft: Either<A, B1>.left,
            caseRight: compose(rf, Either<A, B1>.right)
        )
    }

    func bimap<A1, B1>(
        _ lf: @escaping (A) -> A1,
        _ rf: @escaping (B) -> B1
    ) -> Either<A1, B1> {
        match(
            caseLeft: compose(lf, Either<A1, B1>.left),
            caseRight: compose(rf, Either<A1, B1>.right)
        )
    }
}
