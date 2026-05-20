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

/// Lifts a `KeyPath` into an explicit `@Sendable` getter function.
///
/// Swift's implicit `KeyPath → (Root) -> Value` conversion produces a closure that is
/// **not** annotated `@Sendable`, even though `KeyPath` itself is `Sendable` (see the
/// retroactive conformance above). This blocks key paths from being passed where a
/// `@Sendable` function is required — e.g. into `compose`, `withArg`, `Reducer.lift`,
/// or any `@Sendable`-typed binding.
///
/// `get(_:)` performs the lift explicitly, returning a `@Sendable` closure that captures
/// the (Sendable) key path:
///
/// ```swift
/// let getName: @Sendable (User) -> String = get(\User.name)
/// let predicate = compose(get(\User.name), equals("Alice"))   // tacit again
/// ```
///
/// For the operator form `^\User.name`, see `Sources/CoreFPOperators/Utilities/KeyPath.swift`.
public func get<Root: Sendable, Value: Sendable>(_ keyPath: KeyPath<Root, Value>) -> @Sendable (Root) -> Value {
    { $0[keyPath: keyPath] }
}
