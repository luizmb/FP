public protocol SumType2<A, B> {
    associatedtype A
    associatedtype B

    static func left(_ a: A) -> Self
    static func right(_ b: B) -> Self

    func match<C>(caseLeft: (A) -> C, caseRight: (B) -> C) -> C
}

public extension SumType2 {
    static func from(_ another: any SumType2<A, B>) -> Self {
        another.match(caseLeft: Self.left, caseRight: Self.right)
    }
}

public extension SumType2 {
    static func match<ST1: SumType2, ST2: SumType2, C>(
        _ st1: ST1,
        _ st2: ST2,
        caseLeftLeft: (ST1.A, ST2.A) -> C,
        caseLeftRight: (ST1.A, ST2.B) -> C,
        caseRightLeft: (ST1.B, ST2.A) -> C,
        caseRightRight: (ST1.B, ST2.B) -> C
    ) -> C {
        st1.match { left1 in
            st2.match { left2 in
                caseLeftLeft(left1, left2)
            } caseRight: { right2 in
                caseLeftRight(left1, right2)
            }
        } caseRight: { right1 in
            st2.match { left2 in
                caseRightLeft(right1, left2)
            } caseRight: { right2 in
                caseRightRight(right1, right2)
            }
        }
    }
}

public extension SumType2 {
    var a: A? { match(caseLeft: Optional.some, caseRight: const(nil)) }
    var b: B? { match(caseLeft: const(nil), caseRight: Optional.some) }

    var isA: Bool { match(caseLeft: const(true), caseRight: const(false)) }
    var isB: Bool { match(caseLeft: const(false), caseRight: const(true)) }
}