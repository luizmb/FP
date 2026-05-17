import Foundation

// Hand-written equivalent of what FP's `@Prisms` macro would generate for `Result`.
//
// `Result<Success, Failure>` is generic, so the static `prism` accessor is a computed
// `static var` returning a fresh `Prisms()` per access.
//
// Unlike our own enum types (Either, Validation, Loading), `Result` is part of the
// Swift standard library, so we cannot add `@dynamicMemberLookup` to its declaration.
// The per-case `.success` and `.failure` accessors are therefore kept as explicit
// computed properties rather than being collapsed into a subscript.

public extension Result {
    struct Prisms: Sendable {
        public let success: CoreFP.Prism<Result, Success> = CoreFP.prism(
            preview: { (s: Result) in if case .success(let v) = s { v } else { nil } },
            review: Result.success
        )
        public let failure: CoreFP.Prism<Result, Failure> = CoreFP.prism(
            preview: { (s: Result) in if case .failure(let e) = s { e } else { nil } },
            review: Result.failure
        )
    }

    static var prism: Prisms { Prisms() }

    var success: Success? { a }
    var failure: Failure? { b }

    enum cases: CoreFP.CaseMatchable { // swiftlint:disable:this type_name
        public typealias Subject = Result
        case success, failure

        public func matches(_ value: Result) -> Bool {
            switch (self, value) {
            case (.success, .success): true
            case (.failure, .failure): true
            default:                   false
            }
        }
    }

    func `is`(_ c: cases) -> Bool { c.matches(self) }
}

extension Result: CoreFP.HasCases {
    public typealias Cases = cases
}
