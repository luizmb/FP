import Foundation

public extension SumType2 {
    func bifoldMap<C>(
        leftBy lf: (A) -> C,
        rightBy rf: (B) -> C
    ) -> C {
        match(caseLeft: lf, caseRight: rf)
    }

    func fromLeft(_ otherwise: A) -> A {
        match(caseLeft: identity, caseRight: const(otherwise))
    }

    func fromRight(_ otherwise: B) -> B {
        match(caseLeft: const(otherwise), caseRight: identity)
    }
}
