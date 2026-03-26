// MARK: - Endo<A>

// Endo wraps an endomorphism — a function from a type to itself, `(A) -> A`.
//
// Its defining feature is the Monoid under composition: a sequence of
// transformations collapses into one with `mconcat`, and the identity element
// is the do-nothing function. Use Endo when the transformations are one-way
// (no inverse needed); use `Iso<A, A>` when you also need to undo them.
//
// ```swift
// let trim    = Endo<String> { $0.trimmingCharacters(in: .whitespaces) }
// let lower   = Endo<String> { $0.lowercased() }
// let exclaim = Endo<String> { $0 + "!" }
//
// let normalize: Endo<String> = mconcat([trim, lower, exclaim])
// normalize.run("  HELLO  ")  // "hello!"
// ```

public struct Endo<A>: FunctionWrapper {
    public let runEndo: (A) -> A

    public init(_ fn: @escaping (A) -> A) {
        runEndo = fn
    }

    public func callAsFunction(_ value: A) -> A {
        runEndo(value)
    }
}

/// Free-function constructor — mirrors `Reader { … }` / `iso(get:reverseGet:)` style.
public func endo<A>(_ fn: @escaping (A) -> A) -> Endo<A> {
    Endo(fn)
}
