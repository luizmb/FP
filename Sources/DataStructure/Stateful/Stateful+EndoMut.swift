import CoreFP

// MARK: - Bridges between Stateful<S, Void> and EndoMut<S>
//
// `Stateful<S, Void>` and `EndoMut<S>` are the same type under different names:
// both wrap `(inout S) -> Void`. Conversion in either direction is free —
// no allocation, no copy, just rewrapping the closure.

extension Stateful where A == Void {
    /// Converts to an `EndoMut` wrapping the same closure. Free — no copy.
    public func toEndoMut() -> EndoMut<S> {
        EndoMut(run)
    }
}

extension EndoMut {
    /// Converts to a `Stateful<A, Void>` wrapping the same closure. Free — no copy.
    public func toStateful() -> Stateful<A, Void> {
        Stateful(runEndoMut)
    }
}
