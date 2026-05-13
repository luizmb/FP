// `KeyPath` and `WritableKeyPath` are reference types whose instances are immutable
// after creation — the key path object itself never mutates, even though it enables
// mutations on the `Root`. They are safe to share across isolation boundaries.
//
// Swift 6.3 removed the unconditional `@unchecked Sendable` conformance that
// earlier toolchains provided, leaving `KeyPath` without any Sendable conformance
// in generic contexts. We restore it here retroactively.
extension KeyPath: @retroactive @unchecked Sendable {}
extension WritableKeyPath: @retroactive @unchecked Sendable {}
