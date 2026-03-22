import CoreFP

public extension Validation {
    static func fmap<B>(_ fn: @escaping (A) -> B) -> (Validation<E, A>) -> Validation<E, B> {
        { $0.mapSuccess(fn) }
    }

    func mapSuccess<B>(_ fn: @escaping (A) -> B) -> Validation<E, B> {
        match(
            caseFailure: Validation<E, B>.failure,
            caseSuccess: compose(fn, Validation<E, B>.success)
        )
    }

    func mapFailure<E1: Semigroup>(_ fn: @escaping (E) -> E1) -> Validation<E1, A> {
        match(
            caseFailure: compose(fn, Validation<E1, A>.failure),
            caseSuccess: Validation<E1, A>.success
        )
    }

    func bimap<E1: Semigroup, B>(_ ef: @escaping (E) -> E1, _ af: @escaping (A) -> B) -> Validation<E1, B> {
        match(
            caseFailure: compose(ef, Validation<E1, B>.failure),
            caseSuccess: compose(af, Validation<E1, B>.success)
        )
    }

    func void() -> Validation<E, Void> {
        mapSuccess(ignore)
    }

    static func bimap<E1: Semigroup, B>(
        _ ef: @escaping (E) -> E1,
        _ af: @escaping (A) -> B
    ) -> (Validation<E, A>) -> Validation<E1, B> {
        { $0.bimap(ef, af) }
    }
}
