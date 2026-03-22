import CoreFP

public extension Validation {
    var failure: E? { match(caseFailure: Optional.some, caseSuccess: const(nil)) }
    var success: A? { match(caseFailure: const(nil), caseSuccess: Optional.some) }
    var isFailure: Bool { match(caseFailure: const(true), caseSuccess: const(false)) }
    var isSuccess: Bool { match(caseFailure: const(false), caseSuccess: const(true)) }
}
