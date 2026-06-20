// SPDX-License-Identifier: Apache-2.0

// MARK: - Bridges between Endo<A> and EndoMut<A>

//
// The two types are isomorphic as Monoids. Converting Endo → EndoMut is free
// (no allocation beyond the closure wrapper). Converting EndoMut → Endo always
// makes one copy of the value — that copy is exactly what `Endo` semantics
// require — so prefer `EndoMut` when working with large CoW values.

public extension Endo {
    /// Returns an in-place endomorphism that assigns `self.runEndo(a)` back to `a`.
    func toEndoMut() -> EndoMut<A> {
        EndoMut { a in a = runEndo(a) }
    }
}

public extension EndoMut {
    /// Returns a pure endomorphism by copying the value, mutating the copy,
    /// and returning it. One copy is always made.
    func toEndo() -> Endo<A> {
        Endo { a in
            var copy = a
            runEndoMut(&copy)
            return copy
        }
    }
}
