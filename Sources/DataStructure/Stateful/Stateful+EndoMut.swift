// SPDX-License-Identifier: Apache-2.0
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
        EndoMut(run)
    }
}

extension EndoMut {
    /// Converts to a `Stateful<A, Void>` wrapping the same closure. Free — no copy.
    ///
    /// Use this to sequence an `EndoMut` inside a `flatMap` chain:
    /// ```swift
    /// Stateful<AppState, Void>.get
    ///     .flatMap(const(myEndoMut.toStateful()))
    /// ```
    public func toStateful() -> Stateful<A, Void> {
        Stateful(runEndoMut)
    }
}
