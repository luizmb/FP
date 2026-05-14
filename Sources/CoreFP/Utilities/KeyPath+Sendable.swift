// `KeyPath` and `WritableKeyPath` are reference types whose instances are immutable
// after creation — the key path object itself never mutates, even though it enables
// mutations on the `Root`. They are safe to share across isolation boundaries.
//
// Swift 6.3 removed the unconditional `@unchecked Sendable` conformance that
// earlier toolchains provided, leaving `KeyPath` without any Sendable conformance
// in generic contexts. We restore it here retroactively.
//
// This retroactive `Sendable` conformance is required for:
//   - Lens closures marked `@Sendable` that capture key paths
//   - ix / ix(id:) optic factories that take `KeyPath` parameters
//   - Any `@Sendable` closure that stores or uses a key path
//
// The `@unchecked` annotation is safe because `KeyPath` instances are value-type
// wrappers over immutable metadata — no mutation is possible through the key path
// reference itself.
extension KeyPath: @retroactive @unchecked Sendable {}
extension WritableKeyPath: @retroactive @unchecked Sendable {}
