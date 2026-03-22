import CoreFP

public enum Validation<E: Semigroup, A> {
    case failure(E)
    case success(A)
}

public extension Validation {
    func match<C>(caseFailure: (E) -> C, caseSuccess: (A) -> C) -> C {
        switch self {
        case let .failure(e): caseFailure(e)
        case let .success(a): caseSuccess(a)
        }
    }
}

extension Validation: Equatable where E: Equatable, A: Equatable {}
extension Validation: Comparable where E: Comparable, A: Comparable {
    public static func < (lhs: Validation<E, A>, rhs: Validation<E, A>) -> Bool {
        switch (lhs, rhs) {
        case let (.failure(e1), .failure(e2)): e1 < e2
        case let (.success(a1), .success(a2)): a1 < a2
        case (.failure, .success): true
        case (.success, .failure): false
        }
    }
}
extension Validation: Hashable where E: Hashable, A: Hashable {}
extension Validation: Sendable where E: Sendable, A: Sendable {}
