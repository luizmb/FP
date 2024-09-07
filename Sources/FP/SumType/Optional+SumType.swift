import Foundation

extension Optional: SumType2 {
    public typealias A = Wrapped
    public typealias B = Void

    public static func left(_ a: Wrapped) -> Wrapped? {
        .some(a)
    }

    public static func right(_ b: Void) -> Wrapped? {
        .none
    }

    public func match<C>(caseLeft: (Wrapped) -> C, caseRight: (()) -> C) -> C {
        switch self {
        case let value?: caseLeft(value)
        case nil: caseRight(())
        }
    }
}
