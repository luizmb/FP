import CoreFP

// MARK: - Bridges between Stateful<S, Void> and EndoMut<S>
//
// `Stateful<S, Void>` and `EndoMut<S>` are the same type under different names:
// both wrap `(inout S) -> Void`. They differ only in intent:
//
//   - `EndoMut<S>` is the mutation-oriented monoid — compose chains of in-place
//     transforms and run them together.
//   - `Stateful<S, Void>` is the state monad with a Void result — sequence
//     state-modifying effects via `flatMap`.
//
// Conversion in either direction is free: no allocation, no copy, just
// rewrapping the same closure.

extension Stateful where A == Void {
    /// Converts to an `EndoMut` wrapping the same closure. Free — no copy.
    ///
    /// Use this to pass a stateful action into an optic `lift` or `mconcat`:
    /// ```swift
    /// let reducer: EndoMut<AppState> = stateLens.lift(statefulAction.toEndoMut())
    /// ```
    public func toEndoMut() -> EndoMut<S> {
        // EndoMut now stores a `@Sendable` closure; `Stateful.run` does not (yet).
        // The two function types have identical ABI; the only difference is the
        // type-system annotation. Upgrading via `unsafeBitCast` is sound because
        // `Stateful` already advertises "pure FP state transformation" semantically.
        // When `Stateful` itself becomes `Sendable` in a follow-up, this bitcast
        // can be replaced by `EndoMut(run)` directly.
        let sendableRun = unsafeBitCast(run, to: (@Sendable (inout S) -> Void).self)
        return EndoMut(sendableRun)
    }
}

extension EndoMut {
    /// Converts to a `Stateful<A, Void>` wrapping the same closure. Free — no copy.
    ///
    /// Use this to sequence an `EndoMut` inside a `flatMap` chain:
    /// ```swift
    /// Stateful<AppState, Void>.get
    ///     .flatMap { _ in myEndoMut.toStateful() }
    /// ```
    public func toStateful() -> Stateful<A, Void> {
        Stateful(runEndoMut)
    }
}
